require "rails_helper"

RSpec.describe Callout do
  let(:factory) { :callout }
  include_examples "has_metadata"
  include_examples "has_call_flow_logic"

  describe "associations" do
    it { is_expected.to have_many(:callout_participations).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:batch_operations).dependent(:restrict_with_error) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:status) }

    context "#audio_file" do
      it "validates the content type" do
        callout = build(:callout, audio_file: "image.jpg")

        expect(callout).not_to be_valid
        expect(callout.errors[:audio_file]).to be_present
      end

      it "validates the file size" do
        callout = build(:callout, audio_file: "big_file.mp3")

        expect(callout).not_to be_valid
        expect(callout.errors[:audio_file]).to be_present
      end

      it "allows small audio files" do
        callout = build(:callout, audio_file: "test.mp3")
        expect(callout).to be_valid
      end

      it "allows no audio files" do
        callout = build(:callout)

        expect(callout).to be_valid
      end
    end
  end

  context "saving" do
    it { expect { create(:callout) }.to broadcast(:callout_committed) }
  end

  describe "state_machine" do
    subject { create(factory, factory_attributes) }

    def factory_attributes
      { status: current_status }
    end

    def assert_transitions!
      is_expected.to transition_from(current_status).to(asserted_new_status).on_event(event)
    end

    describe "#start!" do
      let(:current_status) { :initialized }
      let(:asserted_new_status) { :running }
      let(:event) { :start }

      it { assert_transitions! }
    end

    describe "#pause!" do
      let(:current_status) { :running }
      let(:asserted_new_status) { :paused }
      let(:event) { :pause }

      it { assert_transitions! }
    end

    describe "#resume!" do
      let(:asserted_new_status) { :running }
      let(:event) { :resume }

      %i[paused stopped].each do |current_status|
        context "status: '#{current_status}'" do
          let(:current_status) { current_status }
          it { assert_transitions! }
        end
      end
    end

    describe "#stop!" do
      let(:asserted_new_status) { :stopped }
      let(:event) { :stop }

      %i[running paused].each do |current_status|
        context "status: '#{current_status}'" do
          let(:current_status) { current_status }
          it { assert_transitions! }
        end
      end
    end
  end
end
