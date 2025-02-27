
SELECT 
    p.Title,
    u.Reputation AS OwnerReputation,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount,
    COUNT(a.Id) AS AnswerCount
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Posts a ON p.Id = a.ParentId
WHERE 
    p.PostTypeId = 1  
GROUP BY 
    p.Title, u.Reputation
ORDER BY 
    AverageScore DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
