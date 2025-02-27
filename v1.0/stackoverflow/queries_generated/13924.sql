-- Performance benchmarking of Posts and related tables

-- Measure the time taken to retrieve posts with their associated users, votes, and comments
EXPLAIN ANALYZE
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    u.DisplayName AS OwnerDisplayName,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.ViewCount > 0  -- Filtering to only include posts with views
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 100;  -- Limit the result set to 100 posts for faster execution
