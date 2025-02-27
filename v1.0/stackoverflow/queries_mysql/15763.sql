
SELECT 
    p.Title, 
    p.Score, 
    u.DisplayName AS OwnerDisplayName, 
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
    p.Score, 
    u.DisplayName, 
    p.CreationDate, 
    p.ViewCount 
ORDER BY 
    p.CreationDate DESC 
LIMIT 10;
