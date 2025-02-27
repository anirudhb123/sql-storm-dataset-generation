SELECT 
    u.DisplayName,
    p.Title,
    p.Score,
    p.ViewCount,
    p.CreationDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1 -- questions
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
