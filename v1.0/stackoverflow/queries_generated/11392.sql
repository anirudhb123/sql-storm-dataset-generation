-- Performance benchmarking SQL query
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        U.Reputation AS OwnerReputation,
        COUNT(C.Id) AS CommentCount
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= '2023-01-01'  -- Filter for posts created in 2023
    GROUP BY 
        P.Id, U.Reputation
), 
VoteStats AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
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
    PS.OwnerReputation,
    PS.CommentCount,
    COALESCE(VS.UpVotes, 0) AS UpVotes,
    COALESCE(VS.DownVotes, 0) AS DownVotes
FROM 
    PostStats PS
LEFT JOIN 
    VoteStats VS ON PS.PostId = VS.PostId
ORDER BY 
    PS.CreationDate DESC
LIMIT 100;  -- Limit to 100 most recent posts for performance measurement
