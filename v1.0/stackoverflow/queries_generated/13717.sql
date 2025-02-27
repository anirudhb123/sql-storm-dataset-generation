-- Performance Benchmarking Query
-- This query retrieves a summary of posts along with user and vote statistics

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.ViewCount,
    p.Score,
    p.AnswerCount,
    u.DisplayName AS OwnerDisplayName,
    COUNT(DISTINCT v.Id) AS VoteCount,
    COUNT(DISTINCT c.Id) AS CommentCount,
    MAX(b.Date) AS LastBadgeDate,
    COUNT(DISTINCT b.Id) AS BadgeCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    p.CreationDate >= '2023-01-01' -- Filtering posts created in 2023
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.CreationDate DESC; -- Order by the most recent posts
