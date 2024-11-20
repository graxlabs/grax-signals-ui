module Scoring
  class SignInDimension < TaskMetricsDimension
    def initialize(weight: 10)
      super(weight: weight, name: 'signin')
    end
  
    def score_expression
      "IF(tm.signin_count IS NULL, 0, tm.signin_count * #{weight})"
    end
  end
end