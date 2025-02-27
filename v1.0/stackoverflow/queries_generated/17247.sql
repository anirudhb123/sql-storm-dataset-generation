SELECT 
    p.Title, 
    p.CreationDate, 
    u.DisplayName AS Owner, 
    p.ViewCount, 
    p.Score 
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1 -- Filtering for questions only
ORDER BY 
    p.CreationDate DESC
LIMIT 10; -- Getting the latest 10 questions
