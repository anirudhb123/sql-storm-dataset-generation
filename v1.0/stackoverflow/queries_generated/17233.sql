SELECT 
    p.Id AS PostId, 
    p.Title AS PostTitle, 
    p.CreationDate AS PostCreationDate, 
    u.DisplayName AS OwnerDisplayName, 
    COUNT(c.Id) AS CommentCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.PostTypeId = 1  -- Only questions
GROUP BY 
    p.Id, p.Title, p.CreationDate, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 10;  -- Get the most recent 10 questions
