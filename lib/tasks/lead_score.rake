namespace :lead_score do
  desc "Calculate lead score for all leads and update salesforce"
  task :calculate => :environment do
    LeadScoreRunJob.perform_now('rake')
  end
end