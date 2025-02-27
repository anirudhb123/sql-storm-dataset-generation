
SELECT 
    p.Title, 
    p.CreationDate, 
    p.ViewCount, 
    u.DisplayName AS OwnerDisplayName, 
    c.CommentCount 
FROM 
    Posts p 
JOIN 
    Users u ON p.OwnerUserId = u.Id 
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount 
     FROM Comments 
     GROUP BY PostId) c ON p.Id = c.PostId 
WHERE 
    p.PostTypeId = 1  
GROUP BY 
    p.Title, 
    p.CreationDate, 
    p.ViewCount, 
    u.DisplayName, 
    c.CommentCount 
ORDER BY 
    p.CreationDate DESC 
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
