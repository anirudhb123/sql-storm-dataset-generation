-- Performance Benchmarking Query for Stack Overflow Schema

-- This query benchmarks the read performance of various critical components in the Stack Overflow schema
-- by retrieving a summary of posts along with associated user and comment information
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(c.Id) AS CommentCount,
    COALESCE(AVG(v.Type), 0) AS AverageVote
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= '2023-01-01' -- Filter for posts created in 2023
GROUP BY 
    p.Id, u.DisplayName, u.Reputation
ORDER BY 
    p.CreationDate DESC; -- Order by newest posts
