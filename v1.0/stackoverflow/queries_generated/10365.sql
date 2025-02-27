-- Performance Benchmarking Query for Stack Overflow Schema
-- This query measures the execution time of retrieving popular posts and their associated user data.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.Score,
    p.ViewCount,
    u.Id AS UserId,
    u.DisplayName AS UserDisplayName,
    u.Reputation,
    u.CreationDate AS UserCreationDate,
    u.LastAccessDate,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.Score > 0  -- Focusing on popular posts
GROUP BY 
    p.Id, u.Id
ORDER BY 
    p.Score DESC, p.ViewCount DESC, p.CreationDate DESC
LIMIT 100;  -- Limiting to 100 results for performance testing
