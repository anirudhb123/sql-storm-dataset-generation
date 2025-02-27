-- Performance Benchmarking Query 
-- This query retrieves the total count of posts and users 
-- as well as the average score of posts, grouped by post type

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    COUNT(DISTINCT u.Id) AS TotalUsers,
    AVG(p.Score) AS AveragePostScore
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
