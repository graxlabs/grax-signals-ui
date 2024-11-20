module Scoring
  class DeploymentDimension < TaskMetricsDimension
    def initialize(weight: 1000)
      super(weight: weight, name: 'deploy')
    end
  
    def score_expression
      "IF(tm.deploy_flag, #{weight}, 0)"
    end
  end
end