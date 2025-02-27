SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS Author,
    p.Score,
    p.ViewCount,
    c.Id AS CommentId,
    c.Text AS CommentText,
    c.CreationDate AS CommentCreationDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.PostTypeId = 1 -- Retrieve only questions
ORDER BY 
    p.CreationDate DESC
LIMIT 10; -- Limit to the 10 most recent questions
