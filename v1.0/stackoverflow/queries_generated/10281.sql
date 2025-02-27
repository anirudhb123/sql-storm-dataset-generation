-- Performance Benchmarking Query

-- This query benchmarks the performance of retrieving detailed posts along with their related users, votes, and comments.
-- The aim is to test the execution time for a complex query involving multiple joins.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName AS PostOwner,
    u.Reputation AS OwnerReputation,
    COUNT(v.Id) AS VoteCount,
    COUNT(c.Id) AS CommentCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.PostTypeId = 1 -- Only questions
GROUP BY 
    p.Id, u.DisplayName, u.Reputation
ORDER BY 
    p.CreationDate DESC
LIMIT 100; -- Limiting to the most recent 100 questions
