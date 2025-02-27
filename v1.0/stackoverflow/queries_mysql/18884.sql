
SELECT 
    p.Title, 
    u.DisplayName AS OwnerDisplayName, 
    p.ViewCount, 
    p.CreationDate 
FROM 
    Posts p 
JOIN 
    Users u ON p.OwnerUserId = u.Id 
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Title, 
    u.DisplayName, 
    p.ViewCount, 
    p.CreationDate 
ORDER BY 
    p.ViewCount DESC 
LIMIT 10;
