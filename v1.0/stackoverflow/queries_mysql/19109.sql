
SELECT 
    p.Id AS PostId, 
    p.Title, 
    p.ViewCount, 
    u.DisplayName AS OwnerDisplayName, 
    p.CreationDate 
FROM 
    Posts p 
JOIN 
    Users u ON p.OwnerUserId = u.Id 
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Id, 
    p.Title, 
    p.ViewCount, 
    u.DisplayName, 
    p.CreationDate 
ORDER BY 
    p.ViewCount DESC 
LIMIT 10;
