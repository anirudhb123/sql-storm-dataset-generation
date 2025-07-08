
SELECT 
    p.Id AS QuestionId,
    p.Title AS QuestionTitle,
    p.CreationDate AS QuestionCreationDate,
    COALESCE(AVG(DATEDIFF(second, p.CreationDate, a.CreationDate)), 0) AS AverageResponseTime,
    COUNT(a.Id) AS TotalAnswers
FROM 
    Posts p
LEFT JOIN 
    Posts a ON p.Id = a.ParentId
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Id, p.Title, p.CreationDate
ORDER BY 
    AverageResponseTime DESC;
