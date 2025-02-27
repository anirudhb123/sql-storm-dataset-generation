
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    SUM(p.ViewCount) AS TotalViews,
    AVG(p.Score) AS AverageScore,
    COUNT(DISTINCT u.Id) AS UniqueUsers,
    AVG(u.Reputation) AS AverageUserReputation
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 30 DAY  
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;
