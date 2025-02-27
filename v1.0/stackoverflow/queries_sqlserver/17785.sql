
SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS OwnerDisplayName,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    c.Text AS CommentText,
    c.CreationDate AS CommentDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.PostTypeId = 1 
ORDER BY 
    p.CreationDate DESC
OFFSET 0 ROWS
FETCH NEXT 10 ROWS ONLY;
