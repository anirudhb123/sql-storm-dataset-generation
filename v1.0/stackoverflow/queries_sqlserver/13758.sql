
WITH UserStats AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        AVG(Reputation) AS AvgReputation
    FROM Users
    GROUP BY Reputation
),
PostStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        AVG(ViewCount) AS AvgViewCount
    FROM Posts
    GROUP BY ViewCount
),
CommentStats AS (
    SELECT 
        COUNT(*) AS TotalComments
    FROM Comments
    GROUP BY (SELECT NULL)
),
VoteStats AS (
    SELECT 
        COUNT(*) AS TotalVotes
    FROM Votes
    GROUP BY (SELECT NULL)
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
