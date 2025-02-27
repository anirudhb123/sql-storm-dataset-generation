-- Performance Benchmarking Query

-- This query measures the performance of aggregating and joining various tables related to posts, users, and votes
SELECT 
    p.Id AS PostId,
    p.Title,
    p.Score,
    p.ViewCount,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    COUNT(DISTINCT b.Id) AS BadgeCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId 
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    p.CreationDate >= '2023-01-01' -- filtering posts created in the year 2023
GROUP BY 
    p.Id, u.DisplayName, u.Reputation
ORDER BY 
    p.Score DESC, p.ViewCount DESC
LIMIT 100; -- limit to top 100 posts based on score
