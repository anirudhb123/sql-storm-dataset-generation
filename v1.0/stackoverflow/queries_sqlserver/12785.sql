
SELECT 
    pt.Name AS PostType, 
    AVG(p.Score) AS AverageScore, 
    AVG(u.Reputation) AS AverageUserReputation,
    COUNT(p.Id) AS PostCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(YEAR, 1, 0)
GROUP BY 
    pt.Name
ORDER BY 
    AverageScore DESC;
