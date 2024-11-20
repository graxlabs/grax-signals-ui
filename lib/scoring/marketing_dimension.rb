module Scoring
  class MarketingDimension < ScoreDimension
    def initialize(weight: 50)
      super(weight: weight, name: 'marketing')
    end
  
    def required_ctes
      {
        "marketing_metrics" => <<~SQL
          SELECT
            V2.leadid,
            count(V2.campaignid) as marketing_count
          FROM "datalake"."vw_campaign_live" V1
          INNER JOIN "datalake"."vw_campaignmember_live" V2 
            ON (V2.campaignid = V1.id)
          WHERE ((V1.call_to_action__c = 'Analyst Report') 
                 AND (V2.leadid <> '') 
                 AND (date_diff('day', v2.createddate_ts, current_date) <= 90))
          GROUP BY V2.leadid
        SQL
      }
    end
  
    def required_joins
      [
        JoinDefinition.new(
          source: "marketing_metrics",
          alias_name: "mm",
          condition: "mm.leadid = l.id"
        )
      ]
    end
  
    def score_expression
      "IF(mm.marketing_count IS NULL, 0, mm.marketing_count * #{weight})"
    end
  end
end