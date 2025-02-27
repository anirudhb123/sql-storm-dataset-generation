-- Performance Benchmarking Query for StackOverflow Schema

-- This query retrieves the number of posts, average score, and total views 
-- grouped by post type and ordered by the average score in descending order.

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
    p.CreationDate >= DATEADD(year, -1, GETDATE()) -- Last year data
GROUP BY 
    pt.Name
ORDER BY 
    AverageScore DESC;
