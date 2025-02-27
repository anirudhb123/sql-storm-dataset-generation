SELECT 
    u.DisplayName, 
    p.Title, 
    p.CreationDate, 
    p.Score
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1 -- Filtering for Questions
ORDER BY 
    p.Score DESC
LIMIT 10; -- Limit to top 10 questions by score
