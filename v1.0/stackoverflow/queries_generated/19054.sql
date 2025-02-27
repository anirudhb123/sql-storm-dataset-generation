SELECT 
    p.Id AS PostId,
    p.Title,
    p.Score,
    u.DisplayName AS OwnerDisplayName,
    p.CreationDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1 -- Filtering for questions
ORDER BY 
    p.CreationDate DESC
LIMIT 10; -- Limiting to the 10 most recent questions
