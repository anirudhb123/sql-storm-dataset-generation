-- Performance Benchmarking Query
-- This query measures performance by counting the number of posts and their associated votes and comments.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    COUNT(DISTINCT v.Id) AS VoteCount,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COALESCE(SUM(b.Reputation), 0) AS TotalReputation
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    p.Id, p.Title, p.CreationDate
ORDER BY 
    p.CreationDate DESC
LIMIT 1000;  -- Limit to the most recent 1000 posts
