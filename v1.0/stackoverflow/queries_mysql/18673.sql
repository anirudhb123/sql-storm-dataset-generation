
SELECT 
    u.DisplayName AS UserName,
    p.Title AS PostTitle,
    p.CreationDate AS PostDate,
    p.ViewCount AS Views,
    p.Score AS PostScore,
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
    u.DisplayName, p.Title, p.CreationDate, p.ViewCount, p.Score, c.Text, c.CreationDate
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
