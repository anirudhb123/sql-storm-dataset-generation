SELECT 
    u.DisplayName AS UserDisplayName,
    p.Title AS PostTitle,
    p.CreationDate AS PostCreationDate,
    p.Score AS PostScore
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1  -- Filtering for Questions
ORDER BY 
    p.Score DESC
LIMIT 10;  -- Retrieve the top 10 questions by score
