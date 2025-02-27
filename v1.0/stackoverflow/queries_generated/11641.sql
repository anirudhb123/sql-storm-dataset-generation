-- Performance benchmarking query for Stack Overflow schema

-- Measure the read performance by counting total users, posts, and votes
WITH UserCount AS (
    SELECT COUNT(*) AS TotalUsers FROM Users
),
PostCount AS (
    SELECT COUNT(*) AS TotalPosts FROM Posts
),
VoteCount AS (
    SELECT COUNT(*) AS TotalVotes FROM Votes
)

SELECT 
    (SELECT TotalUsers FROM UserCount) AS TotalUsers,
    (SELECT TotalPosts FROM PostCount) AS TotalPosts,
    (SELECT TotalVotes FROM VoteCount) AS TotalVotes
UNION ALL
-- Measure the average score of posts
SELECT AVG(Score) AS AveragePostScore FROM Posts
UNION ALL
-- Measure the average reputation of users
SELECT AVG(Reputation) AS AverageUserReputation FROM Users
UNION ALL
-- Measure the read performance by fetching some data from multiple tables
SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    p.Id, p.Title, u.DisplayName
ORDER BY 
    p.Id
LIMIT 10;  -- Fetch only the first 10 for performance benchmarking
