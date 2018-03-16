# == Schema Information
#
# Table name: batch_operations
#
#  id         :integer          not null, primary key
#  callout_id :integer
#  parameters :jsonb            not null
#  metadata   :jsonb            not null
#  status     :string           not null
#  type       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :integer          not null
#

class BatchOperation::Base < ApplicationRecord
  self.table_name = :batch_operations

  include CustomStoreReaders
  include MetadataHelpers
  include Wisper::Publisher

  belongs_to :account

  conditionally_serialize(:parameters, JSON)

  validates :type, :presence => true
  validates :parameters, :json => true

  include AASM

  aasm :column => :status, :skip_validation_on_save => true do
    state :preview, :initial => true
    state :queued
    state :running
    state :finished

    event :queue, :after_commit => :publish_queued do
      transitions(
        :from => :preview,
        :to => :queued
      )
    end

    event :start do
      transitions(
        :from => :queued,
        :to => :running
      )
    end

    event :finish do
      transitions(
        :from => :running,
        :to => :finished
      )
    end

    event :requeue, :after_commit => :publish_queued do
      transitions(
        :from => :finished,
        :to => :queued
      )
    end
  end

  def serializable_hash(options = nil)
    options ||= {}
    super(
      {
        :methods => :type
      }.merge(options)
    )
  end

  private

  def publish_queued
    broadcast(:batch_operation_queued, self)
  end
end
