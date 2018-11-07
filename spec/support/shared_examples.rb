# frozen_string_literal: true

RSpec.shared_examples_for "aws_sqs_queue_url" do
  describe ".aws_sqs_queue_url" do
    context "custom queue is configured" do
      it "returns the custom queue name" do
        stub_app_config(
          :"#{described_class.to_s.underscore}_queue_url" => "https://example.com/path/to/custom_queue_name"
        )

        expect(
          described_class.aws_sqs_queue_url
        ).to eq("https://example.com/path/to/custom_queue_name")
      end
    end

    context "no custom queue is configured" do
      it "returns the default queue name" do
        stub_app_config(
          default_queue_url: "https://example.com/path/to/queue_name"
        )

        expect(
          described_class.aws_sqs_queue_url
        ).to eq("https://example.com/path/to/queue_name")
      end
    end

    context "passing a job name" do
      it "returns the queue name from the job name" do
        stub_app_config(
          action_mailer_delivery_job_queue_url: "https://example.com/path/to/mailer_queue"
        )

        expect(
          described_class.aws_sqs_queue_url(
            :action_mailer_delivery_job
          )
        ).to eq("https://example.com/path/to/mailer_queue")
      end
    end
  end
end
