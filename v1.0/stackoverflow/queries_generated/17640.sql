SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.Tags
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1 -- Fetching only questions
ORDER BY 
    p.CreationDate DESC
LIMIT 10; -- Limiting to the most recent 10 questions
