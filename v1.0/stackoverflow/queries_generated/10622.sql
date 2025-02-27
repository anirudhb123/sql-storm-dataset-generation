-- Performance Benchmarking Query

-- This query aims to find the average reputation of users who have made posts,
-- along with the count of posts and comments they have made, grouped by their reputation level.

SELECT 
    u.Reputation,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT c.Id) AS TotalComments,
    AVG(u.Reputation) OVER () AS AvgReputation
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON u.Id = c.UserId
GROUP BY 
    u.Reputation
ORDER BY 
    u.Reputation DESC;
