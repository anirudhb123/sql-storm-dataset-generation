
SELECT 
    p.Id AS PostId, 
    p.Title, 
    p.Body, 
    u.DisplayName AS Author, 
    p.CreationDate, 
    p.Score, 
    p.ViewCount 
FROM 
    Posts p 
JOIN 
    Users u ON p.OwnerUserId = u.Id 
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Id, 
    p.Title, 
    p.Body, 
    u.DisplayName, 
    p.CreationDate, 
    p.Score, 
    p.ViewCount 
ORDER BY 
    p.CreationDate DESC 
LIMIT 10;
