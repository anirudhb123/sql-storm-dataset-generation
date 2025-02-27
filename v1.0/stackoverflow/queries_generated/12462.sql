-- Performance Benchmarking Query
-- This query retrieves the total count of posts, the average score of posts, 
-- and the total number of users with at least one badge, grouped by post type

SELECT 
    pt.Name AS PostTypeName,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    COUNT(DISTINCT b.UserId) AS TotalUsersWithBadges
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Badges b ON p.OwnerUserId = b.UserId
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
