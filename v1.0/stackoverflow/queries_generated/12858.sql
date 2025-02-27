-- Performance Benchmarking SQL Query

-- Retrieve the count of posts, users, and votes along with average score of posts
WITH PostStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        AVG(Score) AS AverageScore
    FROM 
        Posts
),
UserStats AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        AVG(Reputation) AS AverageReputation
    FROM 
        Users
),
VoteStats AS (
    SELECT 
        COUNT(*) AS TotalVotes
    FROM 
        Votes
)

SELECT 
    p.TotalPosts,
    p.AverageScore,
    u.TotalUsers,
    u.AverageReputation,
    v.TotalVotes
FROM 
    PostStats p, UserStats u, VoteStats v;

-- Additional query: Top 10 users by reputation and their post count
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
    u.Reputation DESC
LIMIT 10;

-- Additional query: Most active posts (by comment count)
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CommentCount
FROM 
    Posts p
ORDER BY 
    p.CommentCount DESC
LIMIT 10;
