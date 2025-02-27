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
    p.PostTypeId = 1 -- Filtering for questions
ORDER BY 
    p.CreationDate DESC
LIMIT 10; -- Limit the results to the most recent 10 questions
