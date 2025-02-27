SELECT 
    u.DisplayName,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1 -- Considering only Questions
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
