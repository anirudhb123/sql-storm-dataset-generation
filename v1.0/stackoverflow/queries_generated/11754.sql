-- Performance Benchmarking Query for Stack Overflow Schema

-- This query retrieves the number of posts, average score, and total views for each post type
-- It can be used to benchmark performance across different post types

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViews
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Id, pt.Name
ORDER BY 
    TotalPosts DESC;
