SELECT 
    p.Title, 
    u.DisplayName AS OwnerDisplayName, 
    p.CreationDate, 
    p.ViewCount 
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1 -- Filter for Questions
ORDER BY 
    p.CreationDate DESC
LIMIT 10; -- Limit to the most recent 10 questions
