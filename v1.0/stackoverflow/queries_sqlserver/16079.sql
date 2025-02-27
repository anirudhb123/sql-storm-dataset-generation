
SELECT 
    u.DisplayName,
    p.Title,
    p.CreationDate,
    p.Score,
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
ORDER BY 
    p.Score DESC
OFFSET 0 ROWS 
FETCH NEXT 10 ROWS ONLY;
