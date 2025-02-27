
SELECT 
    p.Title,
    p.Score,
    u.DisplayName AS OwnerDisplayName,
    p.CreationDate,
    COUNT(c.Id) AS CommentCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Title, p.Score, u.DisplayName, p.CreationDate
ORDER BY 
    p.Score DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
