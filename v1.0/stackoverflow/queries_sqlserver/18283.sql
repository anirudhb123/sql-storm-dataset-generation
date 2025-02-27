
SELECT 
    p.Title, 
    p.CreationDate, 
    u.DisplayName AS OwnerDisplayName, 
    COUNT(ans.Id) AS AnswerCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Posts ans ON ans.ParentId = p.Id
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Title, p.CreationDate, u.DisplayName
ORDER BY 
    p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
