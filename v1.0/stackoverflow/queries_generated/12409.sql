-- Performance Benchmarking Query
-- This query retrieves the number of posts by each user, 
-- average score of their posts, and total views, 
-- ordered by total views in descending order.

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViews
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalViews DESC;
