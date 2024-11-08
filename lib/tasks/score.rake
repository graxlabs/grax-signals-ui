namespace :scores do
  desc "Calculate lead score for all leads and update salesforce"
  task generate: :environment do
    Rake::Task["scores:leads"].execute
  end

  task leads: :environment do
    LeadScoreRunJob.perform_now('rake')
  end

  task previous: :environment do
    query = File.read(Rails.root.join('lib', 'queries', 'lead_score2.sql'))
    athena = AthenaQuery.new
    results = athena.execute_query(query)
    puts "Results: #{results.size}"
    puts "Results: #{results[0..5].inspect}"
  end
end