
SELECT 
    p.Id AS PostId,
    p.Title,
    p.Score,
    u.DisplayName AS Owner,
    p.CreationDate,
    p.LastActivityDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1 
ORDER BY 
    p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
