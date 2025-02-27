
SELECT 
    u.DisplayName AS UserDisplayName,
    p.Title AS PostTitle,
    p.CreationDate AS PostDate,
    p.Score AS PostScore,
    c.Text AS CommentText,
    c.CreationDate AS CommentDate
FROM 
    Comments c
JOIN 
    Posts p ON c.PostId = p.Id
JOIN 
    Users u ON c.UserId = u.Id
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
