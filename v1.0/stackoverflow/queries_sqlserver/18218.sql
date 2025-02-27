
SELECT 
    p.Title, 
    u.DisplayName AS OwnerDisplayName, 
    p.CreationDate, 
    p.Score 
FROM 
    Posts p 
JOIN 
    Users u ON p.OwnerUserId = u.Id 
WHERE 
    p.PostTypeId = 1 
ORDER BY 
    p.CreationDate DESC 
OFFSET 0 ROWS 
FETCH NEXT 10 ROWS ONLY;
