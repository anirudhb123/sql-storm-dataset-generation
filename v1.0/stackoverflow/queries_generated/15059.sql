SELECT 
    p.Id as PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName as OwnerDisplayName,
    p.Score,
    p.ViewCount,
    COUNT(c.Id) as CommentCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.PostTypeId = 1 -- Filter for Questions
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 10; -- Limit to the latest 10 questions
