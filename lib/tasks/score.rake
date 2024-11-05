namespace :scores do
  desc "Calculate lead score for all leads and update salesforce"
  task :calculate => :environment do
    ScoringRunJob.perform_now('rake')
  end
end