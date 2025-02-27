-- Performance Benchmarking Query

-- This query retrieves the number of posts created by each user along with the average score of their posts,
-- and orders the results to identify which users have the highest engagement on their posts.

SELECT 
    u.DisplayName,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AveragePostScore
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.DisplayName
ORDER BY 
    PostCount DESC, 
    AveragePostScore DESC
LIMIT 100; -- Limit to top 100 users for performance reason
