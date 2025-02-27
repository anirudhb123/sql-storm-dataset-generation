-- Performance Benchmarking SQL Query

-- Query to retrieve a summary of posts along with their related user reputation
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    u.Id AS UserId,
    u.Reputation AS UserReputation,
    COALESCE(COUNT(c.Id), 0) AS CommentCount,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyAmount
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= CURRENT_DATE - INTERVAL '1 month'  -- Filter for recent posts
GROUP BY 
    p.Id, u.Id
ORDER BY 
    p.CreationDate DESC;
