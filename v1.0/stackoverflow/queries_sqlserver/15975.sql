
SELECT 
    u.DisplayName,
    p.Title,
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
GROUP BY 
    u.DisplayName,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    c.Text,
    c.CreationDate
ORDER BY 
    p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
