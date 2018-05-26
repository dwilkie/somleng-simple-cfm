class Callout < ApplicationRecord
  include MetadataHelpers
  include HasCallFlowLogic

  AUDIO_CONTENT_TYPES = %w[audio/mpeg audio/mp3 audio/wav].freeze

  belongs_to :account

  has_many :callout_participations, dependent: :restrict_with_error

  has_many :batch_operations,
           class_name: "BatchOperation::Base",
           dependent: :restrict_with_error

  has_many :callout_populations,
           class_name: "BatchOperation::CalloutPopulation"

  has_many :phone_calls,
           through: :callout_participations

  has_many :remote_phone_call_events,
           through: :phone_calls

  has_many :contacts,
           through: :callout_participations

  store_accessor :metadata, :commune_ids
  attr_accessor :province_id

  has_one_attached :voice

  alias_attribute :calls, :phone_calls

  before_validation :remove_empty_commune_ids

  validates :status, presence: true
  validates :commune_ids, presence: true

  validate  :validate_voice

  delegate :id, :name_en, :name_km, to: :province, prefix: true, allow_nil: true

  include AASM

  aasm column: :status, whiny_transitions: false do
    state :initialized, initial: true
    state :running
    state :paused
    state :stopped

    event :start do
      transitions(
        from: :initialized,
        to: :running
      )
    end

    event :pause do
      transitions(
        from: :running,
        to: :paused
      )
    end

    event :resume do
      transitions(
        from: %i[paused stopped],
        to: :running
      )
    end

    event :stop do
      transitions(
        from: %i[running paused],
        to: :stopped
      )
    end
  end

  def province
    return if commune_ids.blank?
    Pumi::Province.find_by_id(commune_ids.first[0..1])
  end

  private

  def remove_empty_commune_ids
    self.commune_ids = Array(commune_ids).reject(&:blank?)
  end

  # https://github.com/rails/rails/issues/31656
  def validate_voice
    if voice.attached?
      errors.add(:voice, :audio_type) unless audio_file?
      errors.add(:voice, :audio_size) if file_too_big?
    else
      errors.add(:voice, :blank)
    end
  end

  def audio_file?
    voice.blob.content_type.in?(AUDIO_CONTENT_TYPES)
  end

  def file_too_big?
    voice.blob.byte_size.bytes > 10.megabytes
  end
end
