SELECT 
    u.DisplayName AS UserName,
    p.Title AS PostTitle,
    p.CreationDate AS PostCreationDate,
    p.ViewCount,
    p.Score
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1  -- Filtering for Questions
ORDER BY 
    p.CreationDate DESC
LIMIT 
    10;  -- Limiting the results to the latest 10 questions
