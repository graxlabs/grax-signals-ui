module Scoring
  class TaskMetricsDimension < ScoreDimension
    def required_ctes
      {
        "task_metrics" => <<~SQL
          SELECT
            vtl.whoid,
            count_if(((vtl.Subject = 'User Signed In') AND 
                      (date_diff('day', vtl.createddate_ts, current_date) <= 90))) as signin_count,
            count_if(((vtl.Subject LIKE '%Opened%') AND 
                      (date_diff('day', vtl.createddate_ts, current_date) <= 90))) as email_count,
            bool_or(((vtl.Subject LIKE '%Deployment%') AND 
                     (date_diff('day', vtl.createddate_ts, current_date) <= 180))) as deploy_flag
          FROM "datalake"."vw_task_live" vtl
          GROUP BY vtl.whoid
        SQL
      }
    end
  
    def required_joins
      [
        JoinDefinition.new(
          source: "task_metrics",
          alias_name: "tm",
          condition: "tm.whoid = l.id"
        )
      ]
    end
  end
end