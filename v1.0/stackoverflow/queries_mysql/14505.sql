
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    u.DisplayName AS OwnerDisplayName,
    ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    p.Id, 
    p.Title, 
    p.CreationDate, 
    p.Score, 
    p.ViewCount, 
    p.AnswerCount, 
    p.CommentCount, 
    u.DisplayName
HAVING 
    Rank <= 10
ORDER BY 
    p.Score DESC, 
    p.CreationDate DESC;
