SELECT 
    u.DisplayName, 
    p.Title, 
    p.CreationDate, 
    p.ViewCount, 
    p.Score 
FROM 
    Posts p 
JOIN 
    Users u ON p.OwnerUserId = u.Id 
WHERE 
    p.PostTypeId = 1  -- Filtering for questions only
ORDER BY 
    p.Score DESC 
LIMIT 10;  -- Top 10 questions by score
