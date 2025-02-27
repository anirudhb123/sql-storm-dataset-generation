SELECT 
    p.Title,
    u.DisplayName AS OwnerName,
    COUNT(c.Id) AS CommentCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.PostTypeId = 1 -- Filtering for questions only
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    CommentCount DESC
LIMIT 10;
