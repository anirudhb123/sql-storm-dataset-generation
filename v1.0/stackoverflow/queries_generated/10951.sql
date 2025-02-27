-- Performance Benchmarking Query for the StackOverflow schema

-- This query retrieves statistics about posts, including the number of comments, votes,
-- and average score per user along with their join date and reputation.
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    u.CreationDate AS UserCreationDate,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT c.Id) AS TotalComments,
    COUNT(DISTINCT v.Id) AS TotalVotes,
    AVG(p.Score) AS AveragePostScore
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation, u.CreationDate
ORDER BY 
    u.Reputation DESC
LIMIT 100; -- limit the results to top 100 users by reputation
