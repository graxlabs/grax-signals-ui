class LeadScoreSnapshot < ApplicationRecord
  belongs_to :lead, primary_key: :id, foreign_key: :lead_id, optional: true

  validates :lead_id, presence: true
  validates :total_score, presence: true
  validates :dimension_scores, presence: true
  validates :calculated_at, presence: true

  scope :most_recent, -> {
    select("DISTINCT ON (lead_id) *")
      .order("lead_id, calculated_at DESC")
  }
end