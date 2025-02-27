-- Performance Benchmarking Query
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    u.DisplayName AS OwnerName,
    u.Reputation AS OwnerReputation,
    COALESCE(ph.RevisionCount, 0) AS PostHistoryCount,
    COALESCE(c.CommentCount, 0) AS TotalComments
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS RevisionCount 
     FROM PostHistory 
     GROUP BY PostId) ph ON p.Id = ph.PostId
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount 
     FROM Comments 
     GROUP BY PostId) c ON p.Id = c.PostId
WHERE 
    p.CreationDate >= '2023-01-01' -- Filter for posts created in 2023
ORDER BY 
    p.CreationDate DESC
LIMIT 100; -- Limit to latest 100 posts
