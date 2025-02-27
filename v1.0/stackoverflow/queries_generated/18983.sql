SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    p.Score,
    p.ViewCount,
    p.CommentCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1  -- Filter for questions only
ORDER BY 
    p.CreationDate DESC
LIMIT 10;  -- Limit to the most recent 10 questions
