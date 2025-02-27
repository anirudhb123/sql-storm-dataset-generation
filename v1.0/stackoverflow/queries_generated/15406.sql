SELECT 
    p.Id AS PostId, 
    p.Title, 
    p.Body, 
    p.CreationDate, 
    u.DisplayName AS OwnerDisplayName 
FROM 
    Posts p 
JOIN 
    Users u ON p.OwnerUserId = u.Id 
WHERE 
    p.PostTypeId = 1 -- Selecting only questions
ORDER BY 
    p.CreationDate DESC 
LIMIT 10; -- Limit to the last 10 questions
