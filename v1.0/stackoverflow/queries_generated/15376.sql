SELECT 
    p.Id AS PostId, 
    p.Title, 
    p.CreationDate, 
    u.DisplayName AS Author, 
    p.Score, 
    p.ViewCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1  -- Considering we're fetching questions
ORDER BY 
    p.CreationDate DESC
LIMIT 10;  -- Fetching the latest 10 questions
