-- Performance Benchmarking Query for StackOverflow Schema

-- This query retrieves the number of posts, average scores, and average view counts 
-- for each post type, allowing for the analysis of post performance across different 
-- categories.

SELECT 
    pt.Name AS PostType,
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
