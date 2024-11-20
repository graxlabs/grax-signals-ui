WITH sfdc_leads AS (
SELECT 
  id,
  leadsource LIKE 'SFDC%' AND 
  date_diff('day', createddate_ts, current_date) <= 90 as is_sfdc_lead
FROM "datalake"."vw_lead_live"

),

task_metrics AS (
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

),

marketing_metrics AS (
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

),

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
    IF((date_diff('day', current_date, l.createddate_ts) > -30),
          (30 + date_diff('day', current_date, l.createddate_ts)),
          0) as fresh_score,
          IF(sf.is_sfdc_lead, 300, 0) as sfdc_score,
          IF(tm.signin_count IS NULL, 0, tm.signin_count * 10) as signin_score,
          IF(tm.email_count IS NULL, 0, tm.email_count * 10) as email_score,
          IF(tm.deploy_flag, 1000, 0) as deploy_score,
          IF(mm.marketing_count IS NULL, 0, mm.marketing_count * 50) as marketing_score,
    (IF((date_diff('day', current_date, l.createddate_ts) > -30),
          (30 + date_diff('day', current_date, l.createddate_ts)),
          0) + IF(sf.is_sfdc_lead, 300, 0) + IF(tm.signin_count IS NULL, 0, tm.signin_count * 10) + IF(tm.email_count IS NULL, 0, tm.email_count * 10) + IF(tm.deploy_flag, 1000, 0) + IF(mm.marketing_count IS NULL, 0, mm.marketing_count * 50)) as new_lead_score,
    curr.lead_score__c as current_lead_score
  FROM base_leads l
  LEFT JOIN sfdc_leads sf ON sf.id = l.id
        LEFT JOIN task_metrics tm ON tm.whoid = l.id
        LEFT JOIN marketing_metrics mm ON mm.leadid = l.id
  LEFT JOIN "datalake"."vw_lead_live" curr ON curr.id = l.id
)

SELECT 
  id,
  new_lead_score,
  current_lead_score,
  fresh_score,
      sfdc_score,
      signin_score,
      email_score,
      deploy_score,
      marketing_score
FROM lead_scoring
ORDER BY new_lead_score DESC
