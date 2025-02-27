SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS OwnerName,
    t.TagName
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    PostsTags pt ON p.Id = pt.PostId
LEFT JOIN 
    Tags t ON pt.TagId = t.Id
WHERE 
    p.PostTypeId = 1
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
