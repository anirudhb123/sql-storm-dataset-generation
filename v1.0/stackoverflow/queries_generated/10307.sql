-- Performance Benchmarking Query for StackOverflow Schema

-- This query aims to analyze the performance characteristics
-- by aggregating post statistics and user engagement metrics.

SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    U.DisplayName AS OwnerDisplayName,
    COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
    COUNT(CASE WHEN V.Id IS NOT NULL THEN 1 END) AS VoteCount,
    SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    P.Score,
    P.ViewCount,
    P.AnswerCount,
    P.FavoriteCount,
    P.LastActivityDate
FROM 
    Posts P
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
WHERE 
    P.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 YEAR'  -- Filter to the last year
GROUP BY 
    P.Id, P.Title, P.CreationDate, U.DisplayName
ORDER BY 
    P.Score DESC, P.ViewCount DESC;  -- Order by score and view count for performance insights
