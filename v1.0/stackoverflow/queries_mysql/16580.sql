
SELECT 
    u.DisplayName AS UserDisplayName,
    p.Title AS PostTitle,
    p.CreationDate AS PostCreationDate,
    p.Score AS PostScore,
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
    p.CreationDate, 
    p.Score, 
    c.Text, 
    c.CreationDate
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
