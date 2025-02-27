-- Performance Benchmarking Query

-- This query will provide insights into the number of posts, their average scores, 
-- and total views per post type, as well as the count of users and badges associated.
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViews,
    COUNT(DISTINCT u.Id) AS TotalUsers,
    COUNT(DISTINCT b.Id) AS TotalBadges
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
