-- Performance Benchmarking Query

-- This query retrieves the average score of questions and answers, their count, and the number of users participating
SELECT 
    pt.Name AS PostTypeName,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    COUNT(DISTINCT p.OwnerUserId) AS UniqueUserCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    p.Score IS NOT NULL
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;
