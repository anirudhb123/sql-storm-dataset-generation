
SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS OwnerDisplayName,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    c.CommentCount,
    t.TagName
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount 
     FROM Comments 
     GROUP BY PostId) c ON p.Id = c.PostId
LEFT JOIN 
    Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%')
WHERE 
    p.PostTypeId = 1  
GROUP BY 
    p.Id, p.Title, u.DisplayName, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, c.CommentCount, t.TagName
ORDER BY 
    p.Score DESC
LIMIT 10;
