SELECT 
    p.Title,
    p.CreationDate,
    u.DisplayName AS Author,
    p.ViewCount,
    p.Score
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1  -- Selecting only questions
ORDER BY 
    p.CreationDate DESC
LIMIT 10;  -- Limit to the most recent 10 questions
