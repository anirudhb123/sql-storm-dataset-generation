-- Performance Benchmarking Query

-- This query retrieves the number of posts, total votes, and average score of posts grouped by post type.
-- It also includes the total number of users and the average reputation of those users.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    SUM(v.VoteCount) AS TotalVotes,
    AVG(p.Score) AS AverageScore,
    (SELECT COUNT(DISTINCT u.Id) FROM Users u) AS TotalUsers,
    AVG(u.Reputation) AS AverageReputation
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS VoteCount
     FROM Votes
     GROUP BY PostId) v ON p.Id = v.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
