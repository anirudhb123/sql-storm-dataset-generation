SELECT 
    p.Id AS PostId, 
    p.Title, 
    p.CreationDate, 
    u.DisplayName AS Owner, 
    p.Score, 
    p.ViewCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1 -- Only select questions
ORDER BY 
    p.Score DESC
LIMIT 10; -- Get the top 10 questions by score
