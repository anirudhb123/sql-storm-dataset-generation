
SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS OwnerDisplayName,
    p.CreationDate,
    p.Score,
    c.Text AS CommentText,
    c.CreationDate AS CommentDate
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.PostTypeId = 1  
GROUP BY 
    p.Id,
    p.Title,
    u.DisplayName,
    p.CreationDate,
    p.Score,
    c.Text,
    c.CreationDate
ORDER BY 
    p.CreationDate DESC
OFFSET 0 ROWS 
FETCH NEXT 10 ROWS ONLY;
