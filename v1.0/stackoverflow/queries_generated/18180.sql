SELECT 
    p.Id AS PostId,
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
    p.PostTypeId = 1  -- Filter for Questions
ORDER BY 
    p.CreationDate DESC
LIMIT 10;  -- Limit to the 10 most recent questions
