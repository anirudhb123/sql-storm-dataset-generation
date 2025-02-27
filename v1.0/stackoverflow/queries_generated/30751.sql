WITH RecursiveCTE AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.ParentId,
        0 AS Level
    FROM Posts P
    WHERE P.ParentId IS NULL

    UNION ALL

    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.ParentId,
        C.Level + 1
    FROM Posts P
    INNER JOIN RecursiveCTE C ON P.ParentId = C.PostId
)

, PostMetrics AS (
    SELECT 
        R.PostId,
        R.Title,
        R.CreationDate,
        R.ViewCount,
        R.Score,
        R.Level,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY R.Level ORDER BY R.Score DESC) AS Rank,
        MAX(B.Name) AS BestBadge
    FROM RecursiveCTE R
    LEFT JOIN Comments C ON R.PostId = C.PostId
    LEFT JOIN Votes V ON R.PostId = V.PostId
    LEFT JOIN Badges B ON B.UserId = R.PostId
    GROUP BY R.PostId, R.Title, R.CreationDate, R.ViewCount, R.Score, R.Level
)

SELECT 
    PM.PostId,
    PM.Title,
    PM.CreationDate,
    PM.ViewCount,
    PM.Score,
    PM.CommentCount,
    PM.UpVotes,
    PM.DownVotes,
    PM.Level,
    PM.Rank,
    PM.BestBadge,
    COALESCE(NULLIF((SELECT SUM(VB.VoteTypeId) 
                     FROM Votes VB 
                     WHERE VB.PostId = PM.PostId 
                     GROUP BY VB.PostId), 0), 'No Votes') AS VoteSumOrMessage
FROM PostMetrics PM
WHERE PM.Level = 0
ORDER BY PM.Score DESC, PM.ViewCount DESC
LIMIT 10;
