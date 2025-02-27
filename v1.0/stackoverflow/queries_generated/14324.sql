-- Performance Benchmarking SQL Query

-- Measure the execution time for retrieving the most active users based on total votes received
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 
             WHEN v.VoteTypeId = 3 THEN -1 
             ELSE 0 END) AS TotalVotes,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT b.Id) AS TotalBadges
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    u.Reputation > 0  -- Consider only users with positive reputation
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalVotes DESC, TotalPosts DESC
LIMIT 100;  -- Limit result to top 100 users for performance
