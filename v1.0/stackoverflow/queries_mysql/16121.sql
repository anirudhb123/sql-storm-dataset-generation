
SELECT 
    p.Title, 
    p.CreationDate, 
    u.DisplayName AS OwnerDisplayName, 
    p.AnswerCount, 
    p.ViewCount 
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
    p.AnswerCount, 
    p.ViewCount 
ORDER BY 
    p.CreationDate DESC 
LIMIT 10;
