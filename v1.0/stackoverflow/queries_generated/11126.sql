-- Performance Benchmarking Query
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        C.CommentCount,
        U.DisplayName AS OwnerDisplayName,
        P.LastActivityDate,
        COUNT(V.Id) AS TotalVotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 month'  -- Filter for posts created in the last month
    GROUP BY 
        P.Id, U.DisplayName
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.ViewCount,
    PS.Score,
    PS.AnswerCount,
    PS.CommentCount,
    PS.OwnerDisplayName,
    PS.LastActivityDate,
    PS.TotalVotes
FROM 
    PostStats PS
ORDER BY 
    PS.Score DESC, PS.ViewCount DESC -- Order by score and view count for benchmarking results
LIMIT 100; -- Limit to top 100 posts for performance
