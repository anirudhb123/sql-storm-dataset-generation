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
    p.PostTypeId = 1  -- Fetching only questions
ORDER BY 
    p.CreationDate DESC
LIMIT 10;  -- Limiting the results to the latest 10 questions
