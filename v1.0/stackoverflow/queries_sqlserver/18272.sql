
SELECT 
    p.Id AS PostID, 
    p.Title, 
    p.Score, 
    p.ViewCount, 
    u.DisplayName AS Author, 
    p.CreationDate 
FROM 
    Posts p 
JOIN 
    Users u ON p.OwnerUserId = u.Id 
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Id, 
    p.Title, 
    p.Score, 
    p.ViewCount, 
    u.DisplayName, 
    p.CreationDate 
ORDER BY 
    p.CreationDate DESC 
OFFSET 0 ROWS 
FETCH NEXT 10 ROWS ONLY;
