SELECT 
    p.Id AS PostId, 
    p.Title, 
    u.DisplayName AS Owner, 
    p.CreationDate, 
    COUNT(c.Id) AS CommentCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.PostTypeId = 1 -- Only Questions
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.CreationDate DESC;
