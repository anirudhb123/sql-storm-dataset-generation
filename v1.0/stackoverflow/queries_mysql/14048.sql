
SELECT 
    pt.Name AS PostTypeName,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViews,
    MAX(p.CreationDate) AS LastPostDate
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    p.CreationDate >= DATE_SUB(CAST('2024-10-01' AS DATE), INTERVAL 1 YEAR)  
GROUP BY 
    pt.Name, p.Score, p.ViewCount, p.CreationDate
ORDER BY 
    PostCount DESC;
