SELECT 
    p.Id AS PostId,
    p.Title,
    p.Score,
    u.DisplayName AS Author,
    p.CreationDate,
    p.ViewCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1  -- Only select questions
ORDER BY 
    p.CreationDate DESC
LIMIT 10;  -- Limit to the 10 most recent questions
