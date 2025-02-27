SELECT 
    p.Id AS PostId, 
    p.Title, 
    p.CreationDate, 
    p.Score, 
    u.DisplayName AS OwnerDisplayName
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1 -- Considering only Questions
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
