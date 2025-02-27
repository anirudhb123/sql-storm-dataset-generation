SELECT 
    p.Title, 
    u.DisplayName AS OwnerDisplayName, 
    p.CreationDate, 
    p.Score, 
    p.ViewCount, 
    p.AnswerCount 
FROM 
    Posts p 
JOIN 
    Users u ON p.OwnerUserId = u.Id 
WHERE 
    p.PostTypeId = 1 -- Selecting only questions
ORDER BY 
    p.CreationDate DESC 
LIMIT 10;
