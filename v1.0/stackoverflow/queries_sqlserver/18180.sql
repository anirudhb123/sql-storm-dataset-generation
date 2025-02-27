
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS Author,
    p.ViewCount,
    p.Score
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1  
GROUP BY 
    p.Id, 
    p.Title, 
    p.CreationDate, 
    u.DisplayName, 
    p.ViewCount, 
    p.Score
ORDER BY 
    p.CreationDate DESC
OFFSET 0 ROWS 
FETCH NEXT 10 ROWS ONLY;
