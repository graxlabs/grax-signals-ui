namespace :lead_score do
  desc "Calculate lead score for all leads and update salesforce"
  task :calculate => :environment do
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
      print "\nSending Salesforce Update\n"
      salesforce = SalesforceBulk.new
      salesforce.update_records(datalakequery['sfdc_object'], formatted_results)
    end
  end
end