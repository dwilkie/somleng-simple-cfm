require "rails_helper"

RSpec.resource "Batch Operations" do
  header("Content-Type", "application/json")

  get "/api/batch_operations" do
    example "List all Batch Operations" do
      filtered_batch_operation = create(
        :batch_operation,
        account: account,
        metadata: {
          "foo" => "bar"
        }
      )
      create(:batch_operation, account: account)
      create(:batch_operation)

      set_authorization_header(access_token: access_token)
      do_request(
        q: {
          "metadata" => {
            "foo" => "bar"
          }
        }
      )

      expect(response_status).to eq(200)
      parsed_body = JSON.parse(response_body)
      expect(parsed_body.size).to eq(1)
      expect(parsed_body.first.fetch("id")).to eq(filtered_batch_operation.id)
    end
  end

  post "/api/batch_operations" do
    parameter(
      :type,
      "Must be: BatchOperation::CalloutPopulation",
      required: true
    )

    parameter(
      :parameters,
      "Parameters for the batch operation. `limit`, specifies a limit to the number of operations that will occur in the batch operation. `skip_validate_preview_presence` turns off validation for creating batch operations which would not effect any resources"
    )

    parameter(
      :callout_id,
      "The `id` of the callout. Only applicable if the type is `BatchOperation::CalloutPopulation`"
    )

    example "Populate a Callout" do
      explanation <<~HEREDOC
        Creates a batch operation for populating a callout with callout participations.
        Specify `contact_filter_params` in order to filter which contacts will participate in the callout.
      HEREDOC

      callout = create(:callout, account: account)
      body = build_batch_operation_request_body(
        type: "BatchOperation::CalloutPopulation",
        callout_id: callout.id,
        parameters: {
          "skip_validate_preview_presence" => "1",
          "contact_filter_params" => {
            "metadata" => {
              "gender" => "f"
            }
          }
        }
      )

      set_authorization_header(access_token: access_token)
      do_request(callout_id: callout.id, **body)

      assert_batch_operation_created!(account: account, request_body: body)
      expect(callout.reload.callout_populations.count).to eq(1)
    end

    example "Create a Batch Operation with an invalid type", document: false do
      body = build_batch_operation_request_body(
        type: "Contact"
      )

      set_authorization_header(access_token: access_token)
      do_request(body)

      expect(response_status).to eq(422)
    end
  end

  get "/api/batch_operations/:id" do
    example "Retrieve a Batch Operation" do
      batch_operation = create(:batch_operation, account: account)

      set_authorization_header(access_token: access_token)
      do_request(id: batch_operation.id)

      expect(response_status).to eq(200)
      expect(response_body).to eq(batch_operation.to_json)
    end
  end

  patch "/api/batch_operations/:id" do
    example "Update a Batch Operation" do
      batch_operation = create(
        :batch_operation,
        account: account,
        metadata: {
          "foo" => "bar"
        }
      )
      body = build_batch_operation_request_body(
        metadata: {
          "bar" => "foo"
        },
        metadata_merge_mode: "replace",
        parameters: {
          "foo" => "bar"
        }
      )

      set_authorization_header(access_token: access_token)
      do_request(id: batch_operation.id, **body)

      expect(response_status).to eq(204)
      batch_operation.reload
      expect(batch_operation.metadata).to eq(body.fetch(:metadata))
      expect(batch_operation.parameters).to eq(body.fetch(:parameters))
    end
  end

  delete "/api/batch_operations/:id" do
    example "Delete a Batch Operation" do
      batch_operation = create(:batch_operation, account: account)

      set_authorization_header(access_token: access_token)
      do_request(id: batch_operation.id)

      expect(response_status).to eq(204)
      expect(BatchOperation::Base.find_by_id(batch_operation.id)).to eq(nil)
    end

    example "Delete a callout population with callout participations", document: false do
      callout_population = create(:callout_population, account: account)
      create(:callout_participation, callout_population: callout_population)

      set_authorization_header(access_token: access_token)
      do_request(id: callout_population.id)

      expect(response_status).to eq(422)
    end
  end

  post "/api/batch_operations/:batch_operation_id/batch_operation_events" do
    parameter(
      :event,
      "Either `queue` or `requeue`.",
      required: true
    )

    example "Create a Batch Operation Event" do
      batch_operation = create(
        :batch_operation,
        account: account,
        status: BatchOperation::Base::STATE_PREVIEW
      )

      set_authorization_header(access_token: access_token)
      perform_enqueued_jobs do
        do_request(
          batch_operation_id: batch_operation.id,
          event: "queue"
        )
      end

      expect(response_status).to eq(201)
      expect(response_headers.fetch("Location")).to eq(api_batch_operation_path(batch_operation))
      parsed_body = JSON.parse(response_body)
      expect(parsed_body.fetch("status")).to eq("queued")
      expect(batch_operation.reload).to be_finished
    end

    example "Requeue a batch operation", document: false do
      batch_operation = create(
        :batch_operation,
        account: account,
        status: BatchOperation::Base::STATE_FINISHED
      )

      set_authorization_header(access_token: access_token)
      perform_enqueued_jobs do
        do_request(
          batch_operation_id: batch_operation.id,
          event: "requeue"
        )
      end

      expect(response_status).to eq(201)
      parsed_body = JSON.parse(response_body)
      expect(parsed_body.fetch("status")).to eq("queued")
      expect(batch_operation.reload).to be_finished
    end

    example "Queue a finished batch operation", document: false do
      batch_operation = create(
        :batch_operation,
        account: account,
        status: BatchOperation::Base::STATE_FINISHED
      )

      set_authorization_header(access_token: access_token)
      do_request(
        batch_operation_id: batch_operation.id,
        event: "queue"
      )

      expect(response_status).to eq(422)
    end
  end

  let(:access_token) { create_access_token }
  let(:account) { access_token.resource_owner }

  def create_access_token(**options)
    create(
      :access_token,
      permissions: %i[
        contacts_read
        callout_participations_read
        phone_calls_read
        batch_operations_read
        batch_operations_write
      ], **options
    )
  end

  def build_batch_operation_request_body(parameters: {}, metadata: {}, **options)
    {
      metadata: {
        "foo" => "bar"
      }.merge(metadata),
      parameters: {
        "skip_validate_preview_presence" => "1"
      }.merge(parameters)
    }.merge(options)
  end

  def assert_batch_operation_created!(account:, request_body:)
    expect(response_status).to eq(201)
    parsed_response = JSON.parse(response_body)
    expect(parsed_response.fetch("metadata")).to eq(request_body.fetch(:metadata))
    expect(parsed_response.fetch("parameters")).to eq(request_body.fetch(:parameters))
    expect(
      account.batch_operations.find(parsed_response.fetch("id")).class
    ).to eq(request_body.fetch(:type).constantize)
  end
end
