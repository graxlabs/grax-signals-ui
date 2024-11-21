class LeadScoreRunJob < ApplicationJob
  def perform(initiated_by)
    Scoring::LeadScoringService.run_and_store(initiated_by)
  end
end
