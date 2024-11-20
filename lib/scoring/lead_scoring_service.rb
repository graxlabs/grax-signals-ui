module Scoring
  class LeadScoringService
    def self.build_query
      LeadScorer.new
        .add_dimension(FreshnessDimension.new)
        .add_dimension(SfdcDimension.new)
        .add_dimension(SignInDimension.new)
        .add_dimension(EmailDimension.new)
        .add_dimension(DeploymentDimension.new)
        .add_dimension(MarketingDimension.new)
        .build_query
    end
  end
end