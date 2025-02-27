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
    p.PostTypeId = 1  -- Only questions
ORDER BY 
    p.CreationDate DESC
LIMIT 10;  -- Limit to the 10 most recent questions
