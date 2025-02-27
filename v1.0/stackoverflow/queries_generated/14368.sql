-- Benchmarking query to analyze posts with the highest view counts and their associated user information
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.ViewCount,
    u.Id AS UserId,
    u.DisplayName,
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
    p.ViewCount > 1000 -- Only consider posts with more than 1000 views for benchmarking
GROUP BY 
    p.Id, u.Id
ORDER BY 
    p.ViewCount DESC
LIMIT 10; -- Limit the results to the top 10 most viewed posts
