WITH RecursivePostComments AS (
    SELECT P.Id AS PostId, C.Id AS CommentId, C.UserId, C.Text, C.CreationDate, 1 AS Level
    FROM Posts P
    JOIN Comments C ON P.Id = C.PostId
    WHERE P.PostTypeId = 1  -- only include questions
    UNION ALL
    SELECT P.Id AS PostId, C.Id AS CommentId, C.UserId, C.Text, C.CreationDate, RPC.Level + 1
    FROM RecursivePostComments RPC
    JOIN Comments C ON RPC.CommentId = C.Id  -- join on comments to get replies
)
SELECT 
    U.DisplayName AS UserName,
    P.Title AS PostTitle,
    COUNT(DISTINCT C.CommentId) AS TotalComments,
    SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
    SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
    AVG(P.Score) AS AveragePostScore,
    STRING_AGG(T.TagName, ', ') AS Tags,
    LAST_VALUE(C.RevisionGUID) OVER (PARTITION BY P.Id ORDER BY C.CreationDate ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS LatestRevisionGuid
FROM Posts P
JOIN Users U ON P.OwnerUserId = U.Id
LEFT JOIN Comments C ON P.Id = C.PostId
LEFT JOIN Votes V ON P.Id = V.PostId
LEFT JOIN LATERAL (
    SELECT T.TagName 
    FROM Tags T 
    WHERE T.ExcerptPostId = P.Id
) AS T ON TRUE
WHERE P.CreationDate >= NOW() - INTERVAL '1 year'  -- consider recent posts only
GROUP BY U.DisplayName, P.Id, P.Title
HAVING COUNT(DISTINCT C.CommentId) > 5  -- filter for posts with more than 5 comments
ORDER BY TotalComments DESC, AveragePostScore DESC
LIMIT 10;  -- limit results to the top 10
