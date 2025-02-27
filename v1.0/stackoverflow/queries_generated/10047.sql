-- Performance benchmarking query for Stack Overflow schema

-- Retrieve the count of posts, users, and votes along with their average score and reputation
SELECT 
    (SELECT COUNT(*) FROM Posts) AS TotalPosts,
    (SELECT COUNT(*) FROM Users) AS TotalUsers,
    (SELECT COUNT(*) FROM Votes) AS TotalVotes,
    (SELECT AVG(Score) FROM Posts) AS AveragePostScore,
    (SELECT AVG(Reputation) FROM Users) AS AverageUserReputation
UNION ALL
-- Retrieve post types distribution
SELECT 
    PostTypeId,
    COUNT(*) AS PostCount
FROM 
    Posts
GROUP BY 
    PostTypeId
ORDER BY 
    PostTypeId
UNION ALL
-- Retrieve top 10 most voted posts
SELECT 
    Id AS PostId,
    Score 
FROM 
    Posts
ORDER BY 
    Score DESC
LIMIT 10;
