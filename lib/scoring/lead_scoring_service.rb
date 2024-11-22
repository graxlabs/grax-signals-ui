module Scoring
  class LeadScoringService
    def self.scorer
      LeadScorer.new
        .add_dimension(FreshnessDimension.new)
        .add_dimension(SfdcDimension.new)
        .add_dimension(SignInDimension.new)
        .add_dimension(EmailDimension.new)
        .add_dimension(DeploymentDimension.new)
        .add_dimension(MarketingDimension.new)
    end

    def self.build_query
      self.scorer.build_query
    end

    def self.run_and_store(initiated_by)
      scorer = self.scorer
      dimension_weights = scorer.dimensions.map { |d| [d.name, d.weight] }.to_h
      query = scorer.build_query

      # Create scoring run record
      run = ScoringRun.create!(
        name: 'lead_score',
        query: query,
        sfdc_object: 'Lead',
        status: :running,
        initiated_by: initiated_by,
        started_at: Time.current
      )

      begin
        results = AthenaQuery.new.execute_query(query)
        run.update!(records_scored: results.size - 1) # Subtract 1 for headers

        headers = results[0]
        formatted_results = []

        LeadScoreSnapshot.transaction do
          results[1..].each do |r|
            row = headers.zip(r).to_h

            # Create snapshot record
            LeadScoreSnapshot.create!(
              lead_id: row['id'],
              total_score: row['new_lead_score'],
              previous_score: row['current_lead_score'],
              dimension_scores: {
                fresh: {
                  score: row['fresh_score'],
                  weight: dimension_weights['fresh']
                },
                sfdc: {
                  score: row['sfdc_score'],
                  weight: dimension_weights['sfdc']
                },
                signin: {
                  score: row['signin_score'],
                  weight: dimension_weights['signin']
                },
                email: {
                  score: row['email_score'],
                  weight: dimension_weights['email']
                },
                deploy: {
                  score: row['deploy_score'],
                  weight: dimension_weights['deploy']
                },
                marketing: {
                  score: row['marketing_score'],
                  weight: dimension_weights['marketing']
                }
              },
              calculated_at: Time.current,
              scoring_run: run
            )

            # Only update Salesforce if score changed
            if row['new_lead_score'].to_i != row['current_lead_score'].to_i
              formatted_results << {
                "ID" => row['id'],
                "Lead_Score__c" => row['new_lead_score'].to_i,
                "Previous_Lead_Score__c" => row['current_lead_score'].to_i
              }
            end
          end
        end

        # Update Salesforce
        salesforce = SalesforceBulk.new
        processed = salesforce.update_records('Lead', formatted_results)

        run.update!(
          status: :completed,
          completed_at: Time.current,
          records_updated: processed
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