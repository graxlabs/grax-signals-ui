module Scoring
  class LeadScorer
    def initialize
      @dimensions = []
    end
  
    def add_dimension(dimension)
      @dimensions << dimension
      self
    end
  
    def build_query
      ctes = collect_ctes
      joins = collect_joins
      
      # Get both the column definition and the expression for reuse
      dimension_calculations = @dimensions.map do |d| 
        {
          expression: d.score_expression,
          alias: d.score_alias
        }
      end
    
      <<~SQL
        WITH #{ctes.join(",\n\n")},
        
        base_leads AS (
          SELECT
            id,
            createddate_ts
          FROM "datalake"."vw_lead_live"
          WHERE isconverted_b = false 
          AND status <> 'Disqualified'
        ),
        
        lead_scoring AS (
          SELECT
            l.id,
            #{dimension_calculations.map { |d| "#{d[:expression]} as #{d[:alias]}" }.join(",\n          ")},
            (#{dimension_calculations.map { |d| d[:expression] }.join(" + ")}) as new_lead_score,
            curr.lead_score__c as current_lead_score
          FROM base_leads l
          #{joins.join("\n        ")}
          LEFT JOIN "datalake"."vw_lead_live" curr ON curr.id = l.id
        )
        
        SELECT 
          id,
          new_lead_score,
          current_lead_score,
          #{dimension_calculations.map { |d| d[:alias] }.join(",\n      ")}
        FROM lead_scoring
        ORDER BY id
      SQL
    end
  
    private
  
    def collect_ctes
      @dimensions
        .map(&:required_ctes)
        .reduce({}) { |acc, ctes| acc.merge(ctes) }
        .map { |name, sql| "#{name} AS (\n#{sql}\n)" }
    end
  
    def collect_joins
      @dimensions.flat_map(&:required_joins)
                .uniq { |join| join.alias_name }
                .map(&:to_sql)
    end
  end
end