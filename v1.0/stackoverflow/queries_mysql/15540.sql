
SELECT 
    p.Title,
    u.DisplayName AS Owner,
    p.CreationDate,
    p.ViewCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1
GROUP BY 
    p.Title,
    u.DisplayName,
    p.CreationDate,
    p.ViewCount
ORDER BY 
    p.ViewCount DESC
LIMIT 10;
