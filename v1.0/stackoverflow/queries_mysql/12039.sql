
SELECT 
    pt.Name AS PostType,
    DATE_FORMAT(p.CreationDate, '%Y-%m-01') AS CreationMonth,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name, DATE_FORMAT(p.CreationDate, '%Y-%m-01')
ORDER BY 
    pt.Name, CreationMonth;
