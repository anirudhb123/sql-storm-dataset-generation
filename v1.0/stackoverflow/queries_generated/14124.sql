-- Performance benchmarking query for the Stack Overflow schema

-- This query will benchmark the performance of fetching the most recent posts along with user reputation and vote count.
-- It includes the join operations to assess their impact on performance.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    u.Id AS UserId,
    u.DisplayName AS UserDisplayName,
    u.Reputation,
    p.Score AS PostScore,
    p.ViewCount,
    COUNT(v.Id) AS VoteCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year' -- Filter to get posts from the last year
GROUP BY 
    p.Id, u.Id
ORDER BY 
    p.CreationDate DESC
LIMIT 100; -- Limit to 100 results for performance testing
