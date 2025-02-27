-- Performance Benchmarking Query

-- This query retrieves a summary of posts along with their associated users,
-- post types, and their associated vote counts to benchmark performance across tables.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.ViewCount,
    p.Score,
    pt.Name AS PostType,
    u.DisplayName AS OwnerDisplayName,
    COUNT(v.Id) AS VoteCount,
    p.AnswerCount,
    p.CommentCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 YEAR' -- Filtering for recent posts
GROUP BY 
    p.Id, pt.Name, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 100; -- Limiting results for performance considerations
