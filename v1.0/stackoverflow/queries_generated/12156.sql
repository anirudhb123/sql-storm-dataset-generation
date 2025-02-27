-- Performance Benchmarking Query
-- This query retrieves the total number of posts along with their average score and maximum view count, grouped by post type.

SELECT 
    pt.Name AS PostTypeName,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    MAX(p.ViewCount) AS MaxViewCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
