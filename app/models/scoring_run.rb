class ScoringRun < ApplicationRecord
  validates :status, presence: true

  enum status: {
    pending: 'pending',
    running: 'running',
    completed: 'completed',
    failed: 'failed'
  }

  scope :recent, -> { order(created_at: :desc) }

  def duration
    return nil unless completed_at && started_at
    ((completed_at - started_at) / 1.minute).round(2)
  end
end
