-- Performance Benchmarking Query

-- This query retrieves the number of posts, average score, and average view count per post type, 
-- along with the total number of users and total number of badges awarded. 
-- It will help to understand performance metrics across different dimensions.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount,
    (SELECT COUNT(*) FROM Users) AS TotalUsers,
    (SELECT COUNT(*) FROM Badges) AS TotalBadges
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
