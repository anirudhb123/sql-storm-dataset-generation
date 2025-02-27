-- Performance Benchmarking Query
-- This query aims to evaluate the performance of the Stack Overflow schema by gathering key metrics related to posts, users, and votes

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.ViewCount,
    p.Score,
    p.AnswerCount,
    p.CommentCount,
    u.Reputation AS OwnerReputation,
    u.DisplayName AS OwnerDisplayName,
    v.VoteCount,
    COUNT(DISTINCT c.Id) AS CommentCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    (SELECT 
         PostId, 
         COUNT(*) AS VoteCount 
     FROM 
         Votes 
     GROUP BY 
         PostId) v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.CreationDate >= '2022-01-01' -- Filtering posts created in 2022 and later
GROUP BY 
    p.Id, u.Id, v.VoteCount
ORDER BY 
    p.CreationDate DESC
LIMIT 100; -- Limiting the result set for performance measurement
