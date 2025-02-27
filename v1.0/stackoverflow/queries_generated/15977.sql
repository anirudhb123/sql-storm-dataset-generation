SELECT 
    p.Title,
    u.DisplayName AS Owner,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1  -- Filtering for Questions
ORDER BY 
    p.CreationDate DESC
LIMIT 10;  -- Limiting results to the most recent 10 questions
