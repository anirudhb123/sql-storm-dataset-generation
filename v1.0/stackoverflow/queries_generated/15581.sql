SELECT 
    p.Id AS PostId, 
    p.Title, 
    p.Score, 
    u.DisplayName AS OwnerDisplayName, 
    p.CreationDate 
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1 -- Considering only Questions
ORDER BY 
    p.Score DESC 
LIMIT 10;
