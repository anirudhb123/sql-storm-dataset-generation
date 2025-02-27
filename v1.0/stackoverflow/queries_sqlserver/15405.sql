
SELECT 
    p.Id AS PostId, 
    p.Title, 
    p.CreationDate, 
    u.DisplayName AS OwnerDisplayName, 
    pt.Name AS PostTypeName 
FROM 
    Posts p 
JOIN 
    Users u ON p.OwnerUserId = u.Id 
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id 
WHERE 
    p.ViewCount > 100 
GROUP BY 
    p.Id, 
    p.Title, 
    p.CreationDate, 
    u.DisplayName, 
    pt.Name 
ORDER BY 
    p.CreationDate DESC 
OFFSET 0 ROWS 
FETCH NEXT 10 ROWS ONLY;
