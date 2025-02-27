SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS OwnerDisplayName,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    COUNT(c.Id) AS CommentCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.PostTypeId = 1 -- Filters only Questions
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.Score DESC
LIMIT 10;
