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

  task cold_leads: :environment do
    # High probability example
    result = ColdLeadPredictor.predict({
      numberofemployees_i: 100,
      industry: "Technology",
      annualrevenue_f: 1000000,
      country: "United States",
      state: "CA",
      title: "CEO",
      department__c: "Executive",
      leadsource: "Web",
      original_source__c: "Organic Search",
      budget__c_f: 50000
    })
    puts "HIGH QUALITY LEAD RESULT: #{result}"

    # Low probability example
    result = ColdLeadPredictor.predict({
      numberofemployees_i: 5,
      industry: "Unknown",
      annualrevenue_f: 50000,
      country: "Unknown",
      state: nil,
      title: "Sales Manager",
      department__c: nil,
      leadsource: "List",
      original_source__c: "Purchased List",
      budget__c_f: 1000
    })
    puts "LOW QUALITY LEAD RESULT: #{result}"
  end
end
