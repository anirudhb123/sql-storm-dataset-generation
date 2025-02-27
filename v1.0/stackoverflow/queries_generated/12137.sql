-- Performance Benchmarking Query

-- This query retrieves the number of posts, average score, and total view count for each post type
-- The results are grouped by PostTypeId for comparison across different types of posts

SELECT 
    pt.Id AS PostTypeId,
    pt.Name AS PostTypeName,
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
