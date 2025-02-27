SELECT P.Id AS PostId,
       P.Title,
       P.CreationDate,
       U.DisplayName AS OwnerDisplayName,
       P.Score,
       P.ViewCount,
       C.CommentCount,
       A.AcceptedAnswerId
FROM Posts P
JOIN Users U ON P.OwnerUserId = U.Id
LEFT JOIN (
   SELECT PostId, COUNT(*) AS CommentCount
   FROM Comments
   GROUP BY PostId
) C ON P.Id = C.PostId
LEFT JOIN (
   SELECT PostId, MAX(CASE WHEN PostTypeId = 2 THEN Id END) AS AcceptedAnswerId
   FROM Posts
   GROUP BY PostId
) A ON P.Id = A.PostId
WHERE P.PostTypeId = 1
ORDER BY P.CreationDate DESC
LIMIT 10;
