class CreateScoringRuns < ActiveRecord::Migration[7.2]
  def change
    create_table :scoring_runs do |t|
      t.string :name
      t.string :sfdc_object
      t.text :query
      t.datetime :started_at
      t.datetime :completed_at
      t.integer :records_scored
      t.integer :records_updated
      t.string :status
      t.text :error_message
      t.string :initiated_by

      t.timestamps
    end
  end
end
