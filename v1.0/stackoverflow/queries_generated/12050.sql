-- Performance Benchmarking Query

-- This query retrieves the number of posts, the average score of posts, 
-- and the average view count per user with their associated creation date and reputation
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AvgPostScore,
    AVG(p.ViewCount) AS AvgViewCount,
    u.Reputation,
    u.CreationDate
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation, u.CreationDate
ORDER BY 
    TotalPosts DESC;
