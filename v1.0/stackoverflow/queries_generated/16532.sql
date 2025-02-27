SELECT 
    p.Title, 
    p.CreationDate, 
    u.DisplayName AS OwnerDisplayName, 
    p.Score, 
    p.ViewCount, 
    p.AnswerCount 
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1 -- Fetching only questions
ORDER BY 
    p.CreationDate DESC
LIMIT 10; -- Limit to the latest 10 questions
