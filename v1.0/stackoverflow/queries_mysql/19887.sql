
SELECT 
    p.Title,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    p.ViewCount,
    p.Score
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1  
GROUP BY 
    p.Title, 
    p.CreationDate, 
    u.DisplayName, 
    p.ViewCount, 
    p.Score
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
