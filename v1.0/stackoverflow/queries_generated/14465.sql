-- Performance Benchmarking SQL Query 
SELECT 
    u.DisplayName AS UserName,
    p.Title AS PostTitle,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    COALESCE(a.AnswerCount, 0) AS AnswerCount,
    COALESCE(c.CommentCount, 0) AS CommentCount,
    COALESCE(b.BadgeCount, 0) AS BadgeCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    (SELECT ParentId, COUNT(*) AS AnswerCount 
     FROM Posts 
     WHERE PostTypeId = 2  -- Answer
     GROUP BY ParentId) a ON p.Id = a.ParentId
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount 
     FROM Comments 
     GROUP BY PostId) c ON p.Id = c.PostId
LEFT JOIN 
    (SELECT UserId, COUNT(*) AS BadgeCount 
     FROM Badges 
     GROUP BY UserId) b ON u.Id = b.UserId
WHERE 
    p.PostTypeId = 1  -- Question
ORDER BY 
    p.CreationDate DESC
LIMIT 100;  -- Limiting results for performance testing
