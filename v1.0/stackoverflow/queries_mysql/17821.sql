
SELECT 
    p.Id AS PostId, 
    p.Title, 
    u.DisplayName AS Author, 
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
    p.Id, 
    p.Title, 
    u.DisplayName, 
    p.CreationDate, 
    p.Score, 
    p.ViewCount, 
    p.AnswerCount, 
    p.CommentCount
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
