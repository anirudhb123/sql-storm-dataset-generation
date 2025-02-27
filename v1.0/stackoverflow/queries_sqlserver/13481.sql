
WITH PostStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        AVG(Score) AS AvgPostScore,
        COUNT(DISTINCT OwnerUserId) AS UniquePostOwners
    FROM Posts
    GROUP BY 1, 2 -- Adding a GROUP BY to handle aggregates
),
CommentStats AS (
    SELECT 
        COUNT(*) AS TotalComments,
        AVG(Score) AS AvgCommentScore
    FROM Comments
    GROUP BY 1 -- Adding a GROUP BY to handle aggregates
),
UserStats AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        AVG(Reputation) AS AvgUserReputation
    FROM Users
    GROUP BY 1 -- Adding a GROUP BY to handle aggregates
)

SELECT 
    p.TotalPosts,
    p.AvgPostScore,
    p.UniquePostOwners,
    c.TotalComments,
    c.AvgCommentScore,
    u.TotalUsers,
    u.AvgUserReputation
FROM 
    PostStats p,
    CommentStats c,
    UserStats u;
