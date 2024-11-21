WITH lead_scoring AS (
SELECT
  a.ID
, (((((FRESH_SCORE + SFDC_SCORE) + SIGNIN_SCORE) + EMAIL_SCORE) + DEPLOY_SCORE) + MARKETING_SCORE) NEW_LEAD_SCORE
, FRESH_SCORE
, SFDC_SCORE
, SIGNIN_SCORE
, EMAIL_SCORE
, DEPLOY_SCORE
, MARKETING_SCORE
, L.CURRENT_LEAD_SCORE
FROM
  (
   SELECT
     LS.Id
   , FRESH_SCORE
   , IF(SFDC_LEAD_FLAG, 300, 0) SFDC_SCORE
   , IF((SIGNIN_COUNT IS NULL), 0, (SIGNIN_COUNT * 10)) SIGNIN_SCORE
   , IF((EMAIL_COUNT IS NULL), 0, (EMAIL_COUNT * 10)) EMAIL_SCORE
   , IF(DEPLOY_FLAG, 1000, 0) DEPLOY_SCORE
   , IF((MARKETING_COUNT IS NULL), 0, (MARKETING_COUNT * 50)) MARKETING_SCORE
   FROM
     (((
      SELECT
        ID
      , IF((date_diff('day', current_date, createddate_ts) > -30), (30 + date_diff('day', current_date, createddate_ts)), 0) FRESH_SCORE
      , IF(((vll.leadsource LIKE 'SFDC%') AND (date_diff('day', createddate_ts, current_date) <= 90)), true, false) SFDC_LEAD_FLAG
      FROM
        "datalake"."vw_lead_live" vll
      WHERE ((vll.isconverted_b = false) AND (vll.status <> 'Disqualified'))
   )  LS
   LEFT JOIN (
      SELECT
        vtl.whoid
      , count_if(((vtl.Subject = 'User Signed In') AND (date_diff('day', vtl.createddate_ts, current_date) <= 90))) SIGNIN_COUNT
      , count_if(((vtl.Subject LIKE '%Opened%') AND (date_diff('day', vtl.createddate_ts, current_date) <= 90))) EMAIL_COUNT
      , bool_or(((vtl.Subject LIKE '%Deployment%') AND (date_diff('day', vtl.createddate_ts, current_date) <= 180))) DEPLOY_FLAG
      FROM
        "datalake"."vw_task_live" vtl
      GROUP BY vtl.whoid
   )  TS ON (LS.id = TS.whoid))
   LEFT JOIN (
      SELECT
        V2.leadid
      , count(V2.campaignid) MARKETING_COUNT
      FROM
        ("datalake"."vw_campaign_live" V1
      INNER JOIN "datalake"."vw_campaignmember_live" V2 ON (V2.campaignid = V1.id))
      WHERE ((V1.call_to_action__c = 'Analyst Report') AND (V2.leadid <> '') AND (date_diff('day', v2.createddate_ts, current_date) <= 90))
      GROUP BY V2.leadid
   )  MS ON (LS.id = MS.leadid))
) a
LEFT JOIN (
  SELECT
    id,
    lead_score__c as CURRENT_LEAD_SCORE
  FROM "datalake"."vw_lead_live"
) L ON (L.Id = a.Id)
ORDER BY NEW_LEAD_SCORE DESC
)
SELECT ID,NEW_LEAD_SCORE,CURRENT_LEAD_SCORE FROM lead_scoring