SELECT 
    p.Id AS PostID,
    p.Title,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    p.ViewCount,
    p.Score
FROM 
    Posts AS p
JOIN 
    Users AS u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1 -- Filter for questions
ORDER BY 
    p.CreationDate DESC
LIMIT 10; -- Get the latest 10 questions
