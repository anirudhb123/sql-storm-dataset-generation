
SELECT 
    u.DisplayName, 
    p.Title, 
    p.CreationDate, 
    p.Score, 
    p.ViewCount 
FROM 
    Users u 
JOIN 
    Posts p ON u.Id = p.OwnerUserId 
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    u.DisplayName, 
    p.Title, 
    p.CreationDate, 
    p.Score, 
    p.ViewCount 
ORDER BY 
    p.CreationDate DESC 
LIMIT 10;
