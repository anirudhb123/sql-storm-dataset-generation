
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViews
FROM 
    Posts AS p
JOIN 
    PostTypes AS pt ON p.PostTypeId = pt.Id
WHERE 
    p.CreationDate >= CURDATE() - INTERVAL 1 YEAR 
GROUP BY 
    pt.Name
ORDER BY 
    AverageScore DESC;
