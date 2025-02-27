
SELECT 
    u.DisplayName AS UserDisplayName, 
    p.Title AS PostTitle, 
    p.CreationDate AS PostCreationDate, 
    c.Text AS CommentText, 
    c.CreationDate AS CommentCreationDate
FROM 
    Posts p
JOIN 
    Comments c ON p.Id = c.PostId
JOIN 
    Users u ON c.UserId = u.Id
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    u.DisplayName, 
    p.Title, 
    p.CreationDate, 
    c.Text, 
    c.CreationDate
ORDER BY 
    c.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
