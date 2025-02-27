
SELECT 
    p.Title,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    p.Score,
    p.AnswerCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Title, 
    p.CreationDate, 
    u.DisplayName, 
    p.Score, 
    p.AnswerCount
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
