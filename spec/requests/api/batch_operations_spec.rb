require "rails_helper"

RSpec.describe "Batch Operations" do
  include SomlengScfm::SpecHelpers::RequestHelpers

  let(:account_traits) { {} }
  let(:account_attributes) { {} }
  let(:account) { create(:account, *account_traits.keys, account_attributes) }
  let(:access_token_model) { create(:access_token, resource_owner: account) }

  let(:factory_attributes) { { account: account } }
  let(:batch_operation) { create(:batch_operation, factory_attributes) }

  let(:body) { {} }
  let(:metadata) { { "foo" => "bar" } }
  let(:parameters) { { "bar" => "baz" } }

  def setup_scenario
    super
    do_request(method, url, body)
  end

  describe "'/api/batch_operations'" do
    let(:url_params) { {} }
    let(:url) { api_batch_operations_path(url_params) }

    describe "POST" do
      let(:method) { :post }
      let(:asserted_type) { type }

      let(:body) do
        {
          metadata: metadata,
          parameters: parameters,
          type: type
        }
      end

      context "successful requests" do
        let(:asserted_created_batch_operation) { BatchOperation::Base.last }
        let(:parsed_response) { JSON.parse(response.body) }

        let(:parameters) do
          {
            "skip_validate_preview_presence" => "1"
          }
        end

        def assert_created!
          expect(response.code).to eq("201")
          expect(parsed_response).to eq(JSON.parse(asserted_created_batch_operation.to_json))
          expect(parsed_response["metadata"]).to eq(metadata)
          expect(parsed_response["parameters"]).to eq(parameters)
          expect(asserted_created_batch_operation.class.to_s).to eq(asserted_type)
        end

        context "BatchOperation::PhoneCallCreate" do
          let(:remote_request_params) { generate(:twilio_request_params) }
          let(:parameters) { super().merge("remote_request_params" => remote_request_params) }
          let(:type) { "BatchOperation::PhoneCallCreate" }
          it { assert_created! }
        end

        context "BatchOperation::PhoneCallQueue" do
          let(:type) { "BatchOperation::PhoneCallQueue" }
          it { assert_created! }
        end

        context "BatchOperation::PhoneCallQueueRemoteFetch" do
          let(:type) { "BatchOperation::PhoneCallQueueRemoteFetch" }
          it { assert_created! }
        end
      end

      context "invalid request" do
        let(:type) { "Contact" }

        def assert_invalid!
          expect(response.code).to eq("422")
        end

        it { assert_invalid! }
      end
    end

    describe "GET '/'" do
      let(:method) { :get }

      it_behaves_like "resource_filtering" do
        let(:filter_on_factory) { :batch_operation }
        let(:filter_factory_attributes) { factory_attributes }
      end

      it_behaves_like "authorization"
    end
  end

  describe "'/api/callout/:callout_id/batch_operations'" do
    let(:callout) { create(:callout, account: account) }
    let(:url) { api_callout_batch_operations_path(callout) }

    describe "POST" do
      let(:method) { :post }
      let(:type) { "BatchOperation::CalloutPopulation" }
      let(:body) { { type: type } }

      def assert_created!
        expect(response.code).to eq("201")
        expect(account.batch_operations).to be_present
      end

      it { assert_created! }
    end

    describe "GET" do
      let(:method) { :get }
      let(:callout_population) do
        create(
          :callout_population,
          account: account,
          callout: callout
        )
      end

      let(:parsed_response) { JSON.parse(response.body) }

      def setup_scenario
        callout_population
        create(:callout_population, account: account)
        super
      end

      def assert_index!
        super
        expect(parsed_response).to eq(JSON.parse([callout_population].to_json))
      end

      it { assert_index! }
    end
  end

  describe "'/api/batch_operations/:id'" do
    let(:url) { api_batch_operation_path(batch_operation) }

    describe "GET" do
      let(:method) { :get }

      def assert_show!
        expect(response.code).to eq("200")
        expect(response.body).to eq(batch_operation.to_json)
      end

      it { assert_show! }
    end

    describe "PATCH" do
      let(:existing_metadata) { { "bar" => "foo" } }
      let(:factory_attributes) { super().merge("metadata" => existing_metadata) }
      let(:method) { :patch }

      let(:body) do
        {
          metadata: metadata,
          metadata_merge_mode: "replace",
          parameters: parameters
        }
      end

      def assert_update!
        expect(response.code).to eq("204")
        expect(batch_operation.reload.metadata).to eq(metadata)
        expect(batch_operation.parameters).to eq(parameters)
      end

      it { assert_update! }
    end

    describe "DELETE" do
      let(:method) { :delete }

      context "valid request" do
        def assert_destroy!
          expect(response.code).to eq("204")
          expect(BatchOperation::Base.find_by_id(batch_operation.id)).to eq(nil)
        end

        it { assert_destroy! }
      end

      context "invalid request" do
        def setup_scenario
          create(:callout_participation, callout_population: batch_operation)
          super
        end

        def assert_invalid!
          expect(response.code).to eq("422")
        end

        it { assert_invalid! }
      end
    end
  end
end
