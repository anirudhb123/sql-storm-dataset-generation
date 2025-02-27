-- Performance Benchmarking Query
-- This query retrieves the total number of posts, average score, and average view count, along with user reputation stats

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    u.Reputation DESC;
