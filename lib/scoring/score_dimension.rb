module Scoring
  class ScoreDimension
    attr_reader :weight, :name
  
    def initialize(weight:, name:)
      @weight = weight
      @name = name
    end
  
    def score_alias
      "#{name}_score"
    end
  
    def required_ctes
      {}
    end
  
    def required_joins
      []
    end
  
    def score_expression
      raise NotImplementedError, "#{self.class} must implement #score_expression"
    end
  end
end
