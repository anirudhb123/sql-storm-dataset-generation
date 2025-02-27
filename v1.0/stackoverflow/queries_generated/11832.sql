-- Performance Benchmarking Query

-- This query retrieves the most recent activity regarding posts and their associated user data,
-- and evaluates the average vote score and total comments for posts within a specified timeframe.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.ViewCount,
    COALESCE(SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3), 0) AS VoteScore,
    COUNT(c.Id) AS CommentCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    p.CreationDate,
    p.LastActivityDate,
    p.PostTypeId
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 YEAR'  -- Change interval as needed for testing
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    VoteScore DESC, p.LastActivityDate DESC;
