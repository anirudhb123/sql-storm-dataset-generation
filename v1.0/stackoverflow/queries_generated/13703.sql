-- Performance Benchmarking Query

-- This query retrieves the count of posts, comments, and votes per user,
-- along with their average reputation from Users. It also joins with Posts,
-- Comments, and Votes to aggregate the results.

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS PostCount,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    AVG(u.Reputation) OVER() AS AverageReputation
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON u.Id = c.UserId
LEFT JOIN 
    Votes v ON u.Id = v.UserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    UserId;
