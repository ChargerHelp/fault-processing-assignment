class FaultEvent < ApplicationRecord
  belongs_to :customer
  belongs_to :location_asset

  validates :fault_time, :status, :fault_type, :source, presence: true
  validates :urgency_level, inclusion: { in: %w[critical high medium low info resolved] }, allow_blank: true

  # Serialize actions_taken as an array
  serialize :actions_taken, coder: JSON

  # Scope for finding existing events by source ID
  scope :by_source_id, ->(id) { where(id_from_source: id) }

  def resolved?
    resolved_at.present?
  end

  def critical_safety_issue?
    fault_type&.include?("Ground Fault") || urgency_level == "critical"
  end
end
