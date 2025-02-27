
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
JOIN 
    Comments c ON c.PostId = p.Id
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
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
