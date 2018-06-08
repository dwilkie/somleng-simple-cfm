require 'rails_helper'

RSpec.describe User do
  let(:factory) { :user }
  include_examples "has_metadata"

  describe "associations" do
    it { is_expected.to belong_to(:account) }
  end

  describe "validations" do
    def assert_validations!
      is_expected.to validate_presence_of(:email)
      is_expected.to validate_presence_of(:password)
      is_expected.to validate_confirmation_of(:password)
      is_expected.to validate_inclusion_of(:locale).in_array(["en", "km"])
    end

    context "persisted" do
      subject { create(factory) }

      def assert_validations!
        super
        is_expected.to validate_uniqueness_of(:email).case_insensitive
      end

      it { assert_validations! }
    end

    it { assert_validations! }
  end
end
