SELECT 
    u.DisplayName,
    p.Title,
    p.CreationDate,
    p.Score,
    COUNT(c.Id) AS CommentCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.PostTypeId = 1 -- Filtering for Questions
GROUP BY 
    u.DisplayName, p.Title, p.CreationDate, p.Score
ORDER BY 
    p.CreationDate DESC
LIMIT 10; -- Retrieving the most recent 10 questions
