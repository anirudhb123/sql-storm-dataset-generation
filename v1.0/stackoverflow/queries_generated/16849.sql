SELECT 
    p.Title, 
    u.DisplayName as OwnerDisplayName, 
    p.CreationDate, 
    p.Score, 
    COUNT(c.Id) as CommentCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.PostTypeId = 1 -- Only questions
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
