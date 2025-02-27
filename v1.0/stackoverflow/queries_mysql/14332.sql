
SELECT 
    pt.Name AS PostType,
    DATE_FORMAT(p.CreationDate, '%Y-%m-01') AS PostMonth,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViews
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    p.CreationDate >= '2020-01-01' 
GROUP BY 
    pt.Name, DATE_FORMAT(p.CreationDate, '%Y-%m-01')
ORDER BY 
    PostMonth, pt.Name;
