
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
    PostStats AS p CROSS JOIN 
    UserStats AS u CROSS JOIN 
    VoteStats AS v;
