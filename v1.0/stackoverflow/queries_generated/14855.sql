-- Performance Benchmarking Query for Stack Overflow Schema

-- This query retrieves the total number of posts, their average score,
-- and the average view count, grouped by post type, and filters for active users.

SELECT 
    pt.Name AS PostTypeName,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount,
    COUNT(DISTINCT p.OwnerUserId) AS ActiveUsers
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    u.Reputation > 0 -- Only include active users
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
