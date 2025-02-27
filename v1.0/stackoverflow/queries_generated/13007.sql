-- Performance Benchmarking Query

-- This query retrieves the number of posts, average score, and total views
-- grouped by post type, including joins with related tables for user information.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViews,
    COUNT(DISTINCT p.OwnerUserId) AS UniqueUsers
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= '2023-01-01' -- Filter for posts created in 2023
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
