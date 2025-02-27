-- Performance benchmarking query for Stack Overflow schema

-- This query retrieves statistics about posts, users, and their interactions
SELECT 
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    u.DisplayName AS OwnerDisplayName,
    COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
    COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id), 0) AS VoteCount,
    COALESCE((SELECT COUNT(*) FROM Badges b WHERE b.UserId = u.Id), 0) AS BadgeCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= '2023-01-01' -- Filter for posts created in 2023
ORDER BY 
    p.ViewCount DESC
LIMIT 100; -- Limit the results to the top 100 posts by view count
