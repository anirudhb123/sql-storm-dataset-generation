WITH UserReputation AS (
    SELECT Id, Reputation
    FROM Users
    WHERE Reputation IS NOT NULL
), 
PostStatistics AS (
    SELECT P.Id AS PostID, 
           P.Title, 
           P.CreationDate, 
           P.Score, 
           COALESCE(COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END), 0) AS CommentCount,
           COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 WHEN V.VoteTypeId = 3 THEN -1 ELSE 0 END), 0) AS NetVoteScore,
           ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RowNum
    FROM Posts P
    LEFT JOIN Comments C ON C.PostId = P.Id
    LEFT JOIN Votes V ON V.PostId = P.Id
    WHERE P.Created < NOW() - INTERVAL '1 year'
    GROUP BY P.Id
), 
TopPosts AS (
    SELECT PS.PostID, 
           PS.Title, 
           PS.CreationDate, 
           PS.Score, 
           PS.CommentCount, 
           PS.NetVoteScore,
           RANK() OVER (ORDER BY PS.NetVoteScore DESC) AS Rank
    FROM PostStatistics PS
    INNER JOIN UserReputation U ON PS.PostID IN (SELECT P.Id FROM Posts P WHERE P.OwnerUserId = U.Id)
)

SELECT T.Title,
       T.CreationDate,
       T.CommentCount,
       T.NetVoteScore,
       U.DisplayName,
       U.Reputation
FROM TopPosts T
JOIN Users U ON T.PostID IN (SELECT P.Id FROM Posts P WHERE P.OwnerUserId = U.Id)
WHERE T.Rank <= 10
ORDER BY T.NetVoteScore DESC
UNION ALL
SELECT 'Aggregate Score' AS Title,
       NULL AS CreationDate,
       SUM(CommentCount) AS CommentCount,
       SUM(NetVoteScore) AS NetVoteScore,
       NULL AS DisplayName,
       NULL AS Reputation
FROM TopPosts;
