require 'rails_helper'

RSpec.describe Contact do
  let(:factory) { :contact }

  include SomlengScfm::SpecHelpers::MsisdnExamples

  def msisdn_uniqueness_matcher
    super.scoped_to(:account_id)
  end

  include_examples "has_metadata"
  it_behaves_like "has_msisdn"

  describe "associations" do
    def assert_associations!
      is_expected.to belong_to(:account)
      is_expected.to have_many(:callout_participations).dependent(:restrict_with_error)
      is_expected.to have_many(:callouts)
      is_expected.to have_many(:phone_calls).dependent(:restrict_with_error)
      is_expected.to have_many(:remote_phone_call_events)
    end

    it { assert_associations! }
  end

  describe 'store_accessors' do
    it 'store locations metadata' do
      contact = build(:contact, metadata: {
        province_id: '01',
        district_id: '0102',
        commune_id:  '010203',
        village_id:  '01020305'
      })

      expect(contact.province_id).to eq '01'
      expect(contact.district_id).to eq '0102'
      expect(contact.commune_id).to  eq '010203'
      expect(contact.village_id).to  eq '01020305'
    end
  end
end
