-- Performance Benchmarking Query

-- This query retrieves the average score of posts grouped by post type, 
-- alongside the total number of users and post counts for each post type.

SELECT 
    pt.Name AS PostType,
    AVG(p.Score) AS AverageScore,
    COUNT(p.Id) AS TotalPosts,
    COUNT(DISTINCT u.Id) AS TotalUsers
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    pt.Name
ORDER BY 
    AverageScore DESC;
