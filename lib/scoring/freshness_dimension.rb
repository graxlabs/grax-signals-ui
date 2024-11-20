module Scoring
  class FreshnessDimension < ScoreDimension
    def initialize(weight: 1)
      super(weight: weight, name: 'fresh')
    end

    def score_expression
      "IF((date_diff('day', current_date, l.createddate_ts) > -30),
          (30 + date_diff('day', current_date, l.createddate_ts)),
          0)"
    end
  end
end