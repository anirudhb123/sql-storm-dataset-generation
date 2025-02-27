-- Performance benchmarking query
-- This query selects the number of posts by each user along with their reputation
-- It includes joins with the Users and Posts tables to aggregate data effectively

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(p.Id) AS PostCount
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    PostCount DESC, u.Reputation DESC;
