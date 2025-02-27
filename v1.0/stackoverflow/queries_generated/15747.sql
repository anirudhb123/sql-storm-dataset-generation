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
    p.PostTypeId = 1  -- Selecting only Questions
ORDER BY 
    p.CreationDate DESC
LIMIT 10;  -- Fetching the latest 10 questions
