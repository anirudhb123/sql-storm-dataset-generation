SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    p.Score,
    c.CommentCount,
    p.ViewCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    (SELECT 
         PostId, 
         COUNT(*) AS CommentCount 
     FROM 
         Comments 
     GROUP BY 
         PostId) c ON p.Id = c.PostId
WHERE 
    p.PostTypeId = 1  -- Filtering for Questions
ORDER BY 
    p.CreationDate DESC 
LIMIT 10;  -- Limit to the most recent 10 questions
