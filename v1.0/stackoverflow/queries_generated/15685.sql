SELECT 
    p.Id AS PostId, 
    p.Title, 
    u.DisplayName AS OwnerName, 
    p.CreationDate, 
    p.Score 
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1 -- Selecting only questions
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
