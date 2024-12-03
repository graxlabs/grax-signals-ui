module Scoring
  class EmailDimension < TaskMetricsDimension
    def initialize(weight: 5)
      super(weight: weight, name: 'email')
    end

    def score_expression
      "IF(tm.email_count IS NULL, 0, tm.email_count * #{weight})"
    end
  end
end