
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    p.Score,
    p.ViewCount,
    ISNULL(c.CommentCount, 0) AS CommentCount,
    ISNULL(a.AnswerCount, 0) AS AnswerCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
LEFT JOIN 
    (SELECT ParentId, COUNT(*) AS AnswerCount FROM Posts WHERE PostTypeId = 2 GROUP BY ParentId) a ON p.Id = a.ParentId
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Id,
    p.Title,
    p.CreationDate,
    u.DisplayName,
    p.Score,
    p.ViewCount,
    c.CommentCount,
    a.AnswerCount
ORDER BY 
    p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
