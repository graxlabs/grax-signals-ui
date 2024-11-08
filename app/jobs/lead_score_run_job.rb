class LeadScoreRunJob < ApplicationJob
  def perform(initiated_by)
    query = File.read(Rails.root.join('lib', 'queries', 'lead_score2.sql'))
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

      puts "Formatted Results: #{formatted_results[0..5].inspect}"

      print "\nSending Salesforce Update\n"
      salesforce = SalesforceBulk.new
      salesforce.update_records('Lead', formatted_results)

      run.update!(
        status: :completed,
        completed_at: Time.current,
        records_updated: formatted_results.size
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
