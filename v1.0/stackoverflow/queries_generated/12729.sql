-- Performance Benchmarking Query
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    COUNT(v.Id) AS VoteCount,
    COUNT(c.Id) AS CommentCount,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    AVG(u.Reputation) AS AverageUserReputation
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
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year' -- Posts created in the last year
GROUP BY 
    p.Id, u.Reputation
ORDER BY 
    p.ViewCount DESC
LIMIT 100; -- Limit results to the top 100 posts
