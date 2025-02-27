-- Performance benchmarking query to analyze posts and their related comments and votes
SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    P.Score,
    P.ViewCount,
    C.CommentCount,
    V.VoteCount,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation AS OwnerReputation
FROM 
    Posts P
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount 
     FROM Comments 
     GROUP BY PostId) C ON P.Id = C.PostId
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS VoteCount 
     FROM Votes 
     GROUP BY PostId) V ON P.Id = V.PostId
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.CreationDate >= '2023-01-01 00:00:00' -- Adjust the date range as required
ORDER BY 
    P.CreationDate DESC
LIMIT 100; -- Limiting the output for better performance in the benchmark
