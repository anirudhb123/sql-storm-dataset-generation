SELECT 
    p.Title, 
    u.DisplayName AS Owner, 
    p.CreationDate, 
    p.Score,
    COUNT(c.Id) AS CommentCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.PostTypeId = 1  -- Only questions
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.Score DESC
LIMIT 10;  -- Top 10 questions with highest scores
