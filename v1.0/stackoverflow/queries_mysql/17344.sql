
SELECT 
    u.DisplayName, 
    p.Title, 
    p.ViewCount, 
    p.CreationDate, 
    c.Text AS CommentText, 
    c.CreationDate AS CommentCreationDate 
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId 
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    u.DisplayName, 
    p.Title, 
    p.ViewCount, 
    p.CreationDate, 
    c.Text, 
    c.CreationDate 
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
