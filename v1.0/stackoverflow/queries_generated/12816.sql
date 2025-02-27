-- Performance Benchmarking Query
-- This query retrieves the most recent posts, their associated user details, and the count of comments for each post.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(c.Id) AS CommentCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '30 days' -- Only recent posts
GROUP BY 
    p.Id, u.DisplayName, u.Reputation
ORDER BY 
    p.CreationDate DESC
LIMIT 100; -- Limit to top 100 recent posts
