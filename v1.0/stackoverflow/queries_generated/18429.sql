SELECT 
    p.Id AS PostID, 
    p.Title, 
    p.CreationDate, 
    u.DisplayName AS OwnerName, 
    p.ViewCount, 
    p.Score
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1 -- Only select questions
ORDER BY 
    p.CreationDate DESC
LIMIT 10; -- Limit the results to the 10 most recent questions
