SELECT 
    p.Id AS PostId, 
    p.Title, 
    p.CreationDate, 
    u.DisplayName AS OwnerDisplayName, 
    p.Score 
FROM 
    Posts p 
JOIN 
    Users u ON p.OwnerUserId = u.Id 
WHERE 
    p.PostTypeId = 1  -- Filter for Questions
ORDER BY 
    p.CreationDate DESC 
LIMIT 10;  -- Get the most recent 10 questions
