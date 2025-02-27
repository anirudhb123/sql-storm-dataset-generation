-- Performance Benchmarking Query

-- This query benchmarks the time taken to retrieve popular posts along with their details, including user and vote info.
SELECT 
    p.Id AS PostId,
    p.Title,
    p.Body,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(DISTINCT v.Id) AS VoteCount,
    COUNT(DISTINCT c.Id) AS CommentCount
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
    p.Score DESC
LIMIT 100; -- Limit to top 100 popular posts
