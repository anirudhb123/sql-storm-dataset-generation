SELECT 
    u.DisplayName, 
    p.Title, 
    p.Score, 
    p.ViewCount, 
    p.CreationDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1  -- Filtering for Questions
ORDER BY 
    p.CreationDate DESC
LIMIT 10;  -- Getting the latest 10 questions
