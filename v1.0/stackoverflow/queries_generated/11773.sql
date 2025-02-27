-- Performance Benchmarking Query
-- This query retrieves the number of posts by each user along with their reputation,
-- and calculates the average score of the posts for the users.

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AveragePostScore
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    PostCount DESC, u.Reputation DESC;
