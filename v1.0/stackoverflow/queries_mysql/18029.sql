
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS Author,
    c.Text AS Comment,
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
    p.Id, p.Title, p.CreationDate, u.DisplayName, c.Text, c.CreationDate
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
