
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
    p.CreationDate >= CAST(DATEADD(year, -1, '2024-10-01') AS DATE)  
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;
