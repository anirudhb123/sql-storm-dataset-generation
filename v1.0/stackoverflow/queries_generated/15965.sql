SELECT 
    p.Id AS PostId,
    p.Title,
    p.Score,
    p.CreationDate,
    u.DisplayName AS Author
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1  -- Selecting only questions
ORDER BY 
    p.CreationDate DESC
LIMIT 10;  -- Limiting the results to the most recent 10 questions
