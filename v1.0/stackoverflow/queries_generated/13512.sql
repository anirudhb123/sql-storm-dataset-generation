-- Performance Benchmarking Query

-- This query retrieves the performance metrics for posts along with related user information
-- and counts of votes, comments, and associated badges.
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    u.Id AS UserId,
    u.DisplayName AS UserName,
    u.Reputation,
    COUNT(DISTINCT v.Id) AS VoteCount,
    COUNT(DISTINCT c.Id) AS CommentCount,
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
    p.CreationDate >= '2023-01-01'  -- Filter for posts created in 2023
GROUP BY 
    p.Id, u.Id
ORDER BY 
    p.CreationDate DESC;
