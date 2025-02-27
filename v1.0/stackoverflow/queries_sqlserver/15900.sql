
SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS OwnerName,
    p.CreationDate,
    pt.Name AS PostTypeName,
    COUNT(c.Id) AS CommentCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    p.Id, p.Title, u.DisplayName, p.CreationDate, pt.Name
ORDER BY 
    p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
