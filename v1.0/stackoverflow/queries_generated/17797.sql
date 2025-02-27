SELECT 
    p.Id AS PostId, 
    p.Title, 
    u.DisplayName AS OwnerDisplayName, 
    p.CreationDate, 
    p.Score
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1 -- Fetching only Questions
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
