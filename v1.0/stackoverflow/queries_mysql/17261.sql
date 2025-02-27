
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS Author,
    pt.Name AS PostType
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    p.Score >= 0
GROUP BY 
    p.Id, p.Title, p.CreationDate, u.DisplayName, pt.Name
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
