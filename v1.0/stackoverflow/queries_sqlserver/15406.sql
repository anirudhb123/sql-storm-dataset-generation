
SELECT 
    p.Id AS PostId, 
    p.Title, 
    p.Body, 
    p.CreationDate, 
    u.DisplayName AS OwnerDisplayName 
FROM 
    Posts p 
JOIN 
    Users u ON p.OwnerUserId = u.Id 
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Id, 
    p.Title, 
    p.Body, 
    p.CreationDate, 
    u.DisplayName 
ORDER BY 
    p.CreationDate DESC 
OFFSET 0 ROWS 
FETCH NEXT 10 ROWS ONLY;
