-- Performance Benchmarking Query
-- This query retrieves the total count of posts by type, along with their average score and view count,
-- to evaluate the performance and distribution of post types in the Stack Overflow schema.

SELECT 
    pt.Name AS PostTypeName,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
