-- Performance benchmarking query to evaluate users with the highest reputation 
-- and the number of posts they have authored, along with their top voted post title

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(p.Id) AS PostCount,
    MAX(p.Score) AS TopPostScore,
    MAX(p.Title) AS TopPostTitle
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    u.Reputation DESC, 
    PostCount DESC
LIMIT 10;  -- Fetching the top 10 users based on reputation and post count
