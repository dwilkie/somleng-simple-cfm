require "rails_helper"

RSpec.describe Account do
  let(:factory) { :account }
  include_examples "has_metadata"
  include_examples "has_call_flow_logic"

  describe "associations" do
    it { is_expected.to have_many(:users).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:contacts).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:callouts).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:batch_operations).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:callout_participations) }
    it { is_expected.to have_many(:phone_calls) }
    it { is_expected.to have_many(:remote_phone_call_events) }
    it { is_expected.to have_many(:access_tokens).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:sensors) }
    it { is_expected.to have_many(:sensor_rules).through(:sensors) }
    it { is_expected.to have_many(:sensor_events).through(:sensors) }
  end

  describe "validations" do
    it { is_expected.to validate_inclusion_of(:platform_provider_name).in_array(%w[twilio somleng]).allow_nil }
  end

  describe "defaults" do
    subject { create(factory) }

    describe "#permissions" do
      it { expect(subject.permissions).to be_empty }
    end
  end

  describe "#settings" do
    it { expect(subject.settings).to eq({}) }
  end

  describe ".by_platform_account_sid(account_sid)" do
    let(:results) { described_class.by_platform_account_sid(account_sid) }
    let(:twilio_account_sid) { generate(:twilio_account_sid) }
    let(:somleng_account_sid) { SecureRandom.hex }

    let(:account) do
      create(
        :account,
        twilio_account_sid: twilio_account_sid,
        somleng_account_sid: somleng_account_sid
      )
    end

    let(:asserted_results) { [account] }

    def setup_scenario
      super
      account
    end

    def assert_results!
      expect(results).to match_array(asserted_results)
    end

    context "given a Twilio account SID" do
      let(:account_sid) { twilio_account_sid }
      it { assert_results! }
    end

    context "given a Somleng account SID" do
      let(:account_sid) { somleng_account_sid }
      it { assert_results! }
    end

    context "given an account SID which doesn't match any accounts" do
      let(:asserted_results) { [] }
      let(:account_sid) { SecureRandom.hex }
      it { assert_results! }
    end
  end
end
