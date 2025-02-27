-- Performance Benchmarking Query
-- This query retrieves the total number of posts along with their associated user information
-- It also aggregates the score and view count for each post type to provide insight into engagement per post type.

SELECT 
    pt.Name AS PostTypeName,
    COUNT(p.Id) AS TotalPosts,
    SUM(p.Score) AS TotalScore,
    SUM(p.ViewCount) AS TotalViews,
    AVG(u.Reputation) AS AverageUserReputation,
    COUNT(DISTINCT u.Id) AS UniqueUsers
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
