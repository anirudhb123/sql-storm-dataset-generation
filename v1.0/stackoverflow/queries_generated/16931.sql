SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS OwnerDisplayName,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT a.Id) AS AnswerCount
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Posts a ON p.Id = a.ParentId
WHERE 
    p.PostTypeId = 1  -- Considering only questions
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
