-- Performance benchmarking query for Stack Overflow schema 
-- This query will measure the time taken to retrieve statistics about posts along with user information.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.ViewCount,
    p.Score,
    u.Id AS UserId,
    u.DisplayName AS UserDisplayName,
    u.Reputation,
    COUNT(c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    MAX(b.Date) AS LastBadgeDate
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
    p.CreationDate >= '2020-01-01' -- Example filter for recent posts
GROUP BY 
    p.Id, u.Id
ORDER BY 
    p.CreationDate DESC;
