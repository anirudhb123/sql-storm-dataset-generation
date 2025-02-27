-- Performance Benchmarking Query for Stack Overflow Schema

-- This query retrieves the count of posts, average score, 
-- and total views grouped by PostType and CreationDate (month-wise)

SELECT 
    pt.Name AS PostType,
    DATE_TRUNC('month', p.CreationDate) AS PostMonth,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViews
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    p.CreationDate >= '2020-01-01' -- filter for posts created in 2020 and later
GROUP BY 
    pt.Name, PostMonth
ORDER BY 
    PostMonth, pt.Name;
