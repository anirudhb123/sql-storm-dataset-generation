
SELECT TOP 10
    p.Id AS PostId, 
    p.Title, 
    p.Body, 
    u.DisplayName AS OwnerDisplayName, 
    p.CreationDate, 
    p.ViewCount 
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1 
ORDER BY 
    p.CreationDate DESC;
