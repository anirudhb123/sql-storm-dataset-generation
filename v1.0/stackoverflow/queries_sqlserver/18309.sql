
SELECT 
    p.Id as PostId, 
    p.Title, 
    u.DisplayName as OwnerDisplayName, 
    p.CreationDate, 
    p.Score, 
    p.ViewCount 
FROM 
    Posts p 
JOIN 
    Users u ON p.OwnerUserId = u.Id 
WHERE 
    p.PostTypeId = 1 /* Only questions */ 
GROUP BY 
    p.Id, 
    p.Title, 
    u.DisplayName, 
    p.CreationDate, 
    p.Score, 
    p.ViewCount 
ORDER BY 
    p.CreationDate DESC 
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
