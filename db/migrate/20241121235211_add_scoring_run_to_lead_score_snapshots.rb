class AddScoringRunToLeadScoreSnapshots < ActiveRecord::Migration[7.2]
  def change
    add_reference :lead_score_snapshots, :scoring_run, null: true, foreign_key: true
  end
end
