namespace :datalake do
  task update_lead: :environment do
    sql = lead_sql
    AthenaQuery.new.execute_query(sql)
  end
end

def lead_sql
  %|CREATE OR REPLACE VIEW "vw_lead_live" AS
SELECT A.*
FROM
  (object_lead A
INNER JOIN (
   SELECT
     B.Id
   , Max(B.grax__idseq) Latest
   FROM
     object_lead B
   GROUP BY B.ID
)  B ON ((A.Id = B.Id) AND (A.grax__idseq = B.Latest)))
 WHERE (A.grax__deleted IS NULL)|
end