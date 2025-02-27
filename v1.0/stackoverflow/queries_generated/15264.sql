SELECT 
    p.Title,
    p.CreationDate,
    u.DisplayName AS Owner,
    p.Score,
    p.ViewCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1  -- Only include Questions
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
