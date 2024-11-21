class LeadScoreRunJob < ApplicationJob
  def perform(initiated_by)
    query = Scoring::LeadScoringService.build_query
    run = ScoringRun.create!(
      name: 'lead_score',
      query: query,
      sfdc_object: 'Lead',
      status: :running,
      initiated_by: initiated_by,
      started_at: Time.current
    )

    begin
      puts "Executing Athena Query"
      athena = AthenaQuery.new
      results = athena.execute_query(query)
      puts "Results: #{results.size}"
      run.update!(records_scored: results.size)

      formatted_results = []
      results[1..].each do |row|
        id = row[0]
        new_score = row[1].to_i
        current_score = row[2].to_i

        if new_score != current_score
          formatted_results << {
            "ID" => id,
            "Lead_Score__c" => new_score,
            "Previous_Lead_Score__c" => current_score
          }
        end
      end

      print "\nSending Salesforce Update\n"
      salesforce = SalesforceBulk.new
      processed = salesforce.update_records('Lead', formatted_results)
      puts "Processed #{processed} records"

      run.update!(
        status: :completed,
        completed_at: Time.current,
        records_updated: processed
      )
    rescue => e
      run.update!(
        status: :failed,
        error_message: e.message,
        completed_at: Time.current
      )
      raise e
    end
  end
end
