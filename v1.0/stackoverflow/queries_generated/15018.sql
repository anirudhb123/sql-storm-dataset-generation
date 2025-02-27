SELECT 
    u.DisplayName,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1 -- Selecting only questions
ORDER BY 
    p.Score DESC
LIMIT 10; -- Limit the results to top 10 questions by score
