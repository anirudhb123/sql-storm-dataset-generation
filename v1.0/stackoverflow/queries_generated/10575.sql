-- Performance Benchmarking Query
WITH PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        U.DisplayName AS OwnerDisplayName,
        U.Reputation AS OwnerReputation,
        COUNT(DISTINCT C.Id) AS CommentCount,
        MAX(V.CreationDate) AS LastVoteDate
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= '2023-01-01' -- considering posts created in 2023
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, P.AnswerCount, U.DisplayName, U.Reputation
),
VoteStatistics AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN VoteTypeId = 6 THEN 1 END) AS CloseVotes
    FROM 
        Votes
    GROUP BY 
        PostId
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.AnswerCount,
    PS.CommentCount,
    PS.OwnerDisplayName,
    PS.OwnerReputation,
    VS.UpVotes,
    VS.DownVotes,
    VS.CloseVotes,
    PS.LastVoteDate
FROM 
    PostStatistics PS
LEFT JOIN 
    VoteStatistics VS ON PS.PostId = VS.PostId
ORDER BY 
    PS.Score DESC, PS.ViewCount DESC
LIMIT 100;  -- Limiting to top 100 posts for performance assessment
