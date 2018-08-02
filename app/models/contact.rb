class Contact < ApplicationRecord
  include MsisdnHelpers
  include MetadataHelpers

  store_accessor :metadata, :commune_ids

  belongs_to :account

  has_many :callout_participations,
           dependent: :restrict_with_error

  has_many :callouts,
           through: :callout_participations

  has_many :phone_calls,
           dependent: :restrict_with_error

  has_many :remote_phone_call_events,
           through: :phone_calls

  before_validation :normalize_commune_ids

  validates :msisdn,
            uniqueness: { scope: :account_id }

  delegate :call_flow_logic,
           to: :account,
           allow_nil: true

  def self.has_locations_in(commune_ids)
    where(
      "\"#{table_name}\".metadata->'commune_ids' ?| array[:commune_ids]",
      commune_ids: commune_ids
    )
  end

  private

  def normalize_commune_ids
    commune_ids = metadata["commune_ids"]
    return if commune_ids.blank?
    return unless commune_ids.is_a?(String)
    metadata["commune_ids"] = commune_ids.split(/\s+/)
  end
end
