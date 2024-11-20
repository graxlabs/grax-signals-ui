SELECT A.*
FROM
  (datalake.object_campaignmember A
INNER JOIN (
   SELECT
     B.Id
   , Max(B.grax__idseq) Latest
   FROM
     datalake.object_campaignmember B
   GROUP BY B.ID
)  B ON ((A.Id = B.Id) AND (A.grax__idseq = B.Latest)))
 WHERE (A.grax__deleted IS NULL)