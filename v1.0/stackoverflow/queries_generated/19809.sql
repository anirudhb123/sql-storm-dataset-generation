SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS OwnerDisplayName,
    p.CreationDate,
    p.ViewCount,
    p.Score
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1 -- Selecting only Questions
ORDER BY 
    p.Score DESC
LIMIT 10; -- Get top 10 questions by score
