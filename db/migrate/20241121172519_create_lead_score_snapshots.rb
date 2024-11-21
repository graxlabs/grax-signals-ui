class CreateLeadScoreSnapshots < ActiveRecord::Migration[7.2]
  def change
    create_table :lead_score_snapshots do |t|
      t.string :lead_id
      t.integer :total_score
      t.integer :previous_score
      t.jsonb :dimension_scores
      t.datetime :calculated_at

      t.timestamps
    end
    add_index :lead_score_snapshots, :lead_id
    add_index :lead_score_snapshots, :calculated_at
  end
end
