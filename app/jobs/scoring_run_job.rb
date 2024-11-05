class ScoringRunJob < ApplicationJob
  def perform(initiated_by)
    file = File.read(Rails.root.join('lib', 'queries', 'data_lake_queries.json'))
    queries_hash = JSON.parse(file)
    queries_hash.each do |datalakequery|
      puts datalakequery['name'] + " : " + datalakequery['sfdc_object'] + ' : ' + datalakequery['query']
      run = ScoringRun.create!(
        name: datalakequery['name'],
        query: datalakequery['query'],
        sfdc_object: datalakequery['sfdc_object'],
        status: :running,
        initiated_by: initiated_by,
        started_at: Time.current
      )

      begin 
        puts "Executing Athena Query"
        athena = AthenaQuery.new
        results = athena.execute_query(datalakequery['query'])
        formatted_results = results.map do |row|
            {
                results[0][0] => row[0],
                results[0][1] => row[1].to_i
            }
        end
        run.update!(records_scored: results.size)

        print "\nSending Salesforce Update\n"
        salesforce = SalesforceBulk.new
        result = salesforce.update_records(datalakequery['sfdc_object'], formatted_results)
        puts(result.inspect)

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
end