namespace :scores do
  desc "Calculate lead score for all leads and update salesforce"
  task :generate, [:initiated_by] => :environment do |t, args|
    args.with_defaults(initiated_by: 'rake')
    Rake::Task["scores:leads"].invoke(args[:initiated_by])
  end

  task :leads, [:initiated_by] => :environment do |t, args|
    LeadScoreRunJob.perform_now(args[:initiated_by])
  end

  task previous: :environment do
    query = File.read(Rails.root.join('lib', 'queries', 'lead_score2.sql'))
    athena = AthenaQuery.new
    results = athena.execute_query(query)
    puts "Results: #{results.size}"
    puts "Results: #{results[0..5].inspect}"
  end
end