
SELECT 
    p.Title, 
    u.DisplayName as Owner, 
    p.Score, 
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
    p.Score, 
    p.CreationDate 
ORDER BY 
    p.Score DESC 
LIMIT 10;
