
SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS Owner,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    t.TagName
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%')
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Id, 
    p.Title, 
    u.DisplayName, 
    p.CreationDate, 
    p.Score, 
    p.ViewCount, 
    p.AnswerCount, 
    p.CommentCount, 
    t.TagName
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
