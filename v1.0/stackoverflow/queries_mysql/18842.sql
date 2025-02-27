
SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS OwnerDisplayName,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.Tags
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1  
GROUP BY 
    p.Id, p.Title, u.DisplayName, p.CreationDate, p.Score, p.ViewCount, p.Tags
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
