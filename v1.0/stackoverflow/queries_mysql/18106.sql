
SELECT 
    u.DisplayName, 
    p.Title, 
    p.ViewCount, 
    p.CreationDate 
FROM 
    Posts p 
JOIN 
    Users u ON p.OwnerUserId = u.Id 
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    u.DisplayName, 
    p.Title, 
    p.ViewCount, 
    p.CreationDate 
ORDER BY 
    p.ViewCount DESC 
LIMIT 10;
