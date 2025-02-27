-- Performance Benchmarking Query for Stack Overflow Schema

-- This query retrieves the total number of posts, users, votes, comments, and badges for benchmarking purposes,
-- along with the average score of posts and average reputation of users.

SELECT 
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT u.Id) AS TotalUsers,
    COUNT(DISTINCT v.Id) AS TotalVotes,
    COUNT(DISTINCT c.Id) AS TotalComments,
    COUNT(DISTINCT b.Id) AS TotalBadges,
    AVG(p.Score) AS AveragePostScore,
    AVG(u.Reputation) AS AverageUserReputation
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId;
