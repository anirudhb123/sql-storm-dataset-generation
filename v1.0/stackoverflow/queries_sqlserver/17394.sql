
SELECT 
    p.Title, 
    p.CreationDate, 
    p.Score, 
    u.DisplayName AS OwnerDisplayName, 
    COUNT(co.Id) AS CommentCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments co ON p.Id = co.PostId
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Title, 
    p.CreationDate, 
    p.Score, 
    u.DisplayName
ORDER BY 
    p.CreationDate DESC
OFFSET 0 ROWS 
FETCH NEXT 10 ROWS ONLY;
