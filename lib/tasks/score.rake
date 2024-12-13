namespace :scores do
  desc "Calculate lead score for all leads and update salesforce"
  task :generate, [:initiated_by] => :environment do |t, args|
    args.with_defaults(initiated_by: 'rake')
    Rake::Task["scores:leads"].invoke(args[:initiated_by])
  end

  task :leads, [:initiated_by] => :environment do |t, args|
    LeadScoreRunJob.perform_now(args[:initiated_by])
  end

  task compare: :environment do
    LeadScoreCompareJob.perform_now
  end
end
