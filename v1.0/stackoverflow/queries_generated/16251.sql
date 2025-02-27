SELECT 
    p.Id AS PostId, 
    p.Title, 
    p.CreationDate, 
    p.Score, 
    u.DisplayName AS OwnerDisplayName, 
    u.Reputation
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1  -- Filter for Questions
ORDER BY 
    p.CreationDate DESC
LIMIT 10;  -- Limit to the latest 10 questions
