
SELECT 
    pt.Name AS PostType,
    FORMAT(p.CreationDate, 'yyyy-MM') AS CreationMonth,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name, FORMAT(p.CreationDate, 'yyyy-MM')
ORDER BY 
    pt.Name, CreationMonth;
