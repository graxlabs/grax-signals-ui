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

    def self.run_and_store
      scorer = self.scorer
      dimension_weights = scorer.dimensions.map { |d| [d.name, d.weight] }.to_h
      results = AthenaQuery.new.execute_query(scorer.build_query)

      headers = results[0]

      LeadScoreSnapshot.transaction do
        results[1..].each do |r|
          row = headers.zip(r).to_h
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
            calculated_at: Time.current
          )
        end
      end
    end
  end
end