class LeadScoreRunJob < ApplicationJob
  def perform(initiated_by)
    run = ScoringRun.create!(
      status: :running,
      initiated_by: initiated_by,
      started_at: Time.current
    )

    begin
      counter = 0
      file = File.read(Rails.root.join('lib', 'queries', 'data_lake_queries.json'))
      queries_hash = JSON.parse(file)
      queries_hash.each do |datalakequery|
        print datalakequery['name'] + " : " + datalakequery['sfdc_object'] + ' : ' + datalakequery['query']
        print "\nExecuting Athena Query\n"
        athena = AthenaQuery.new
        results = athena.execute_query(datalakequery['query'])
        formatted_results = results.map do |row|
            {
                results[0][0] => row[0],
                results[0][1] => row[1].to_i
            }
        end
        counter += results.size
        print "\nSending Salesforce Update\n"
        salesforce = SalesforceBulk.new
        salesforce.update_records(datalakequery['sfdc_object'], formatted_results)
      end

      run.update!(
        status: :completed,
        completed_at: Time.current,
        records_scored: counter, 
        records_updated: counter 
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