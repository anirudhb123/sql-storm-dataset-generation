SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS Author,
    p.CreationDate,
    p.ViewCount,
    p.Score
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1  -- Only questions
ORDER BY 
    p.CreationDate DESC
LIMIT 
    10;  -- Get the most recent 10 questions
