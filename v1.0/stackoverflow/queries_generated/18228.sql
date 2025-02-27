SELECT 
    p.Title, 
    u.DisplayName AS Owner, 
    p.CreationDate, 
    p.Score, 
    p.ViewCount 
FROM 
    Posts p 
JOIN 
    Users u ON p.OwnerUserId = u.Id 
WHERE 
    p.PostTypeId = 1  -- Fetching only questions 
ORDER BY 
    p.CreationDate DESC 
LIMIT 10;  -- Limiting to the most recent 10 questions
