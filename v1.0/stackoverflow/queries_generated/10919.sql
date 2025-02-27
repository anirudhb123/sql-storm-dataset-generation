-- Performance Benchmarking Query

-- This query measures performance by retrieving the total number of posts, 
-- along with their associated users and votes, to assess the efficiency of 
-- joins on large tables.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.Score,
    p.ViewCount,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    COUNT(v.Id) AS VoteCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 1000; -- Limit for sample size
