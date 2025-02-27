-- Performance Benchmarking SQL Query

-- This query retrieves the count of posts and their average score by post type.
-- Additionally, it gathers info on the number of users who have posted
-- and how many badges they have earned.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    COUNT(DISTINCT u.Id) AS TotalUsers,
    SUM(CASE WHEN b.UserId IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges
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
    pt.Name;
