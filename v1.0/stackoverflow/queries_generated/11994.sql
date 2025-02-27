-- Performance Benchmarking Query

-- This query retrieves the count of various post types, their average score, 
-- and the total number of users who have posted, along with the most recent activity date per user.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    COUNT(DISTINCT u.Id) AS TotalUsers,
    MAX(p.LastActivityDate) AS MostRecentActivity
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
