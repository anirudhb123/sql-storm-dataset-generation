-- Performance Benchmarking Query

-- This query retrieves user statistics and the number of posts, comments, and votes they received.
-- It includes basic user information, aggregates the number of posts they created, comments
-- they made, and votes they received, grouped by user, and orders the results by user reputation.

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS PostCount,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount
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
    u.Reputation DESC
LIMIT 100; -- Limiting to top 100 users by reputation for performance evaluation
