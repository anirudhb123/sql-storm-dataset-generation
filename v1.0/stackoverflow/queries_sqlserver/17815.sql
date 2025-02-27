
SELECT 
    p.Title,
    p.Score,
    u.DisplayName AS OwnerDisplayName,
    p.CreationDate
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
    p.CreationDate
ORDER BY 
    p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
