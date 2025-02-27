
SELECT 
    p.Title, 
    u.DisplayName AS OwnerDisplayName, 
    p.CreationDate, 
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
    u.DisplayName, 
    p.CreationDate, 
    p.Score, 
    p.AnswerCount
ORDER BY 
    p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
