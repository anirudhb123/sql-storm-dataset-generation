
SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS Owner,
    p.CreationDate,
    p.Score,
    postType.Name AS PostType
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    PostTypes postType ON p.PostTypeId = postType.Id
WHERE 
    p.ViewCount > 100
GROUP BY 
    p.Id, 
    p.Title, 
    u.DisplayName, 
    p.CreationDate, 
    p.Score, 
    postType.Name
ORDER BY 
    p.CreationDate DESC
OFFSET 0 ROWS
FETCH NEXT 10 ROWS ONLY;
