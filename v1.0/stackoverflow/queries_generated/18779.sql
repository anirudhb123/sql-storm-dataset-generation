SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    p.Score,
    p.ViewCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1 -- Filtering to get only Questions
ORDER BY 
    p.CreationDate DESC
LIMIT 10; -- Limiting to the most recent 10 questions
