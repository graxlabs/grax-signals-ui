namespace :scores do
  desc "Calculate lead score for all leads and update salesforce"
  task generate: :environment do
    ScoringRunJob.perform_now('rake')
  end
end