module Scoring
  class SfdcDimension < ScoreDimension
    def initialize(weight: 300)
      super(weight: weight, name: 'sfdc')
    end

    def required_ctes
      {
        "sfdc_leads" => <<~SQL
          SELECT
            id,
            leadsource LIKE 'SFDC%' AND
            date_diff('day', createddate_ts, current_date) <= 90 as is_sfdc_lead
          FROM lead_live
        SQL
      }
    end

    def required_joins
      [
        JoinDefinition.new(
          source: "sfdc_leads",
          alias_name: "sf",
          condition: "sf.id = l.id"
        )
      ]
    end

    def score_expression
      "IF(sf.is_sfdc_lead, #{weight}, 0)"
    end
  end
end