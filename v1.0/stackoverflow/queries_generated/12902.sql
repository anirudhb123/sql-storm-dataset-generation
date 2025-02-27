-- Performance benchmarking query for the StackOverflow schema

-- This query will join several tables to analyze post activity and user engagement.

SELECT 
    p.Id AS PostID,
    p.Title,
    u.DisplayName AS OwnerDisplayName,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    p.AnswerCount,
    COALESCE(c.CommentCount, 0) AS CommentCount,
    COALESCE(b.BadgeCount, 0) AS BadgeCount,
    COALESCE(v.VoteCount, 0) AS VoteCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON c.PostId = p.Id
LEFT JOIN 
    (SELECT UserId, COUNT(*) AS BadgeCount FROM Badges GROUP BY UserId) b ON b.UserId = u.Id
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS VoteCount FROM Votes GROUP BY PostId) v ON v.PostId = p.Id
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'  -- Filter for posts created in the last year
ORDER BY 
    p.CreationDate DESC;  -- Order by the most recent posts first
