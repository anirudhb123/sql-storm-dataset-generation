-- Performance Benchmarking SQL Query

-- This query will measure the performance of various table joins and aggregates.
-- It retrieves the number of posts, their average score, and the number of associated comments per user.

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AveragePostScore,
    COUNT(c.Id) AS TotalComments
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalPosts DESC
LIMIT 100; -- Limit to top 100 users by post count
