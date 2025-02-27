-- Performance Benchmarking Query

-- This query retrieves user and post statistics for performance analysis
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS PostCount,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(COALESCE(v.Score, 0)) AS TotalVoteScore,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    MAX(p.CreationDate) AS LastPostDate
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    PostCount DESC
LIMIT 100; -- Limiting to top 100 users based on post count
