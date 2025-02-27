-- Performance Benchmarking Query
-- This query retrieves the numbers of users, posts, comments, and votes, along with average view count per post and user reputation.
WITH UserStats AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        AVG(Reputation) AS AvgReputation
    FROM Users
),
PostStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        AVG(ViewCount) AS AvgViewCount
    FROM Posts
),
CommentStats AS (
    SELECT 
        COUNT(*) AS TotalComments
    FROM Comments
),
VoteStats AS (
    SELECT 
        COUNT(*) AS TotalVotes
    FROM Votes
)
SELECT 
    u.TotalUsers,
    u.AvgReputation,
    p.TotalPosts,
    p.AvgViewCount,
    c.TotalComments,
    v.TotalVotes
FROM 
    UserStats u,
    PostStats p,
    CommentStats c,
    VoteStats v;
