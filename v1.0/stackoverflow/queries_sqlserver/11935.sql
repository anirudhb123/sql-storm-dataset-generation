
WITH PostStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        AVG(ViewCount) AS AverageViews
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
CommentStats AS (
    SELECT 
        COUNT(*) AS TotalComments
    FROM 
        Comments
),
VoteStats AS (
    SELECT 
        COUNT(*) AS TotalVotes
    FROM 
        Votes
)

SELECT 
    p.TotalPosts,
    p.AverageViews,
    u.TotalUsers,
    u.AverageReputation,
    c.TotalComments,
    v.TotalVotes
FROM 
    PostStats AS p
CROSS JOIN 
    UserStats AS u
CROSS JOIN 
    CommentStats AS c
CROSS JOIN 
    VoteStats AS v;
