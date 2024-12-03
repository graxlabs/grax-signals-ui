module Scoring
  class LeadScorer
    attr_reader :dimensions

    def initialize
      @dimensions = []
      @base_ctes = {
        "lead_live" => File.read(Rails.root.join('lib', 'queries', 'lead_live_cte.sql')),
        "task_live" => File.read(Rails.root.join('lib', 'queries', 'task_live_cte.sql')),
        "campaign_live" => File.read(Rails.root.join('lib', 'queries', 'campaign_live_cte.sql')),
        "campaignmember_live" => File.read(Rails.root.join('lib', 'queries', 'campaignmember_live_cte.sql')),
      }
    end

    def add_dimension(dimension)
      @dimensions << dimension
      self
    end

    def build_query
      ctes = collect_all_ctes
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

      #{build_scoring_cte(dimension_calculations, joins)}

      #{build_final_select(dimension_calculations)}
      SQL
    end

    private

    def collect_all_ctes
      # Start with base CTEs
      all_ctes = @base_ctes.map { |name, sql| "#{name} AS (\n#{sql}\n)" }

      # Add dimension CTEs
      dimension_ctes = @dimensions
        .map(&:required_ctes)
        .reduce({}) { |acc, ctes| acc.merge(ctes) }
        .map { |name, sql| "#{name} AS (\n#{sql}\n)" }

      all_ctes + dimension_ctes
    end

    def collect_joins
      @dimensions.flat_map(&:required_joins)
                .uniq { |join| join.alias_name }
                .map(&:to_sql)
    end

    def build_scoring_cte(dimension_calculations, joins)
      <<~SQL
        lead_scoring AS (
          SELECT
            l.id,
            #{dimension_calculations.map { |d| "#{d[:expression]} as #{d[:alias]}" }.join(",\n          ")},
            CASE
              WHEN l.status = 'Disqualified' THEN 0
              ELSE (#{dimension_calculations.map { |d| d[:expression] }.join(" + ")})
            END as new_lead_score,
            curr.lead_score__c as current_lead_score
          FROM lead_live l
          #{joins.join("\n        ")}
          LEFT JOIN lead_live curr ON curr.id = l.id
          WHERE l.isconverted_b = false
        )
      SQL
    end

    def build_final_select(dimension_calculations)
      <<~SQL
        SELECT
          id,
          new_lead_score,
          current_lead_score,
          #{dimension_calculations.map { |d| d[:alias] }.join(",\n        ")}
        FROM lead_scoring
      SQL
    end
  end
end