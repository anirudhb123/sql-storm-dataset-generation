-- Performance Benchmarking Query
-- This query retrieves the total number of posts and their various metrics grouped by post type,
-- along with the total number of users and their average reputation

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    SUM(p.Score) AS TotalScore,
    SUM(p.ViewCount) AS TotalViews,
    AVG(u.Reputation) AS AverageUserReputation,
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
    TotalPosts DESC;
