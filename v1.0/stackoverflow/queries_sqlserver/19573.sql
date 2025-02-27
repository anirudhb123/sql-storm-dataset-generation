
SELECT 
    u.DisplayName AS UserDisplayName, 
    p.Title AS PostTitle, 
    p.CreationDate AS PostCreationDate, 
    p.ViewCount, 
    p.Score
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1
GROUP BY 
    u.DisplayName, 
    p.Title, 
    p.CreationDate, 
    p.ViewCount, 
    p.Score
ORDER BY 
    p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
