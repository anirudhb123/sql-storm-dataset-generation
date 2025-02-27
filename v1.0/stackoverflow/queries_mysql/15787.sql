
SELECT 
    p.Title,
    p.CreationDate,
    u.DisplayName AS Owner
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Title,
    p.CreationDate,
    u.DisplayName
ORDER BY 
    p.ViewCount DESC
LIMIT 10;
