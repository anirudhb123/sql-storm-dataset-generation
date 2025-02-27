-- Performance benchmarking query for Stack Overflow schema

WITH PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        COALESCE(U.DisplayName, 'Deleted User') AS OwnerDisplayName,
        COALESCE(COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= DATEADD(year, -1, GETDATE())  -- Posts created in the last year
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, P.AnswerCount, U.DisplayName
)

SELECT 
    PM.PostId,
    PM.Title,
    PM.CreationDate,
    PM.ViewCount,
    PM.Score,
    PM.AnswerCount,
    PM.OwnerDisplayName,
    PM.CommentCount,
    PM.UpVoteCount,
    PM.DownVoteCount,
    RANK() OVER (ORDER BY PM.ViewCount DESC) AS ViewRank,
    RANK() OVER (ORDER BY PM.Score DESC) AS ScoreRank
FROM 
    PostMetrics PM
ORDER BY 
    PM.ViewCount DESC, PM.Score DESC;
