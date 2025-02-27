-- Performance Benchmarking Query
-- Fetching User Reputation, Number of Posts, and Average View Count
-- Grouped by User and ordered by Reputation

SELECT 
    u.Id AS UserId,
    u.Reputation,
    COUNT(p.Id) AS NumberOfPosts,
    AVG(p.ViewCount) AS AverageViewCount
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id, u.Reputation
ORDER BY 
    u.Reputation DESC;
