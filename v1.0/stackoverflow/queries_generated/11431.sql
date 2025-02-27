-- Performance benchmarking query for StackOverflow schema

-- Measure the number of posts with their associated user reputation and score
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    u.Reputation AS UserReputation,
    COUNT(c.Id) AS CommentCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '30 days'  -- filter for posts created in the last 30 days
GROUP BY 
    p.Id, u.Reputation
ORDER BY 
    p.Score DESC,          -- primary order by score
    UserReputation DESC    -- secondary order by user's reputation
LIMIT 
    100;                   -- limit results to top 100 posts 
