
SELECT 
    p.Id AS PostId,
    u.DisplayName AS UserName,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Id, u.DisplayName, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
