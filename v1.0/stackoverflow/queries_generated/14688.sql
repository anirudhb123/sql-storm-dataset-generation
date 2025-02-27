-- Performance Benchmarking Query

-- This query retrieves information on posts along with user details, vote counts, and badge information for benchmarking performance.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.ViewCount,
    p.Score,
    u.Id AS UserId,
    u.DisplayName AS UserName,
    u.Reputation AS UserReputation,
    COUNT(v.Id) AS VoteCount,
    COUNT(b.Id) AS BadgeCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    p.Id, u.Id
ORDER BY 
    p.CreationDate DESC
LIMIT 100; -- Adjust the limit for performance testing
