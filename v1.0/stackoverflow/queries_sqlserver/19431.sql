
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
    p.PostTypeId = 1 
GROUP BY 
    p.Title, 
    p.CreationDate, 
    u.DisplayName
ORDER BY 
    p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
