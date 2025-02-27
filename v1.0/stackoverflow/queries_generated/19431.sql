SELECT 
    p.Title, 
    p.CreationDate, 
    u.DisplayName AS Owner, 
    COUNT(ans.Id) AS AnswerCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Posts ans ON p.Id = ans.ParentId
WHERE 
    p.PostTypeId = 1 -- Filter for Questions
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
