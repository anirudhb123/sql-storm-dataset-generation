-- Performance Benchmarking Query

-- This query benchmarks the performance of retrieving user activity on posts,
-- including comments and votes, along with the number of badges earned by each user.
-- The query aggregates data by user and orders the results by reputation.

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT c.Id) AS TotalComments,
    COUNT(DISTINCT v.Id) AS TotalVotes,
    COUNT(DISTINCT b.Id) AS TotalBadges,
    SUM(COALESCE(v.BountyAmount, 0)) AS TotalBountyAwarded
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON u.Id = c.UserId
LEFT JOIN 
    Votes v ON u.Id = v.UserId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    u.Reputation DESC;

-- Note: The use of LEFT JOIN ensures that users without posts, comments, votes, or badges are still included in the result set.
