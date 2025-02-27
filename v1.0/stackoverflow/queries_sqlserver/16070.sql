
SELECT 
    p.Title, 
    u.DisplayName AS OwnerDisplayName, 
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
    p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
