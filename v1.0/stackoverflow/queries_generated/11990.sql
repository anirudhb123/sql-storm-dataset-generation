-- Performance benchmarking query on Stack Overflow schema

-- This query aims to find the number of posts, comments, and users, as well as their average score and view counts.
WITH PostStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        AVG(Score) AS AveragePostScore,
        AVG(ViewCount) AS AverageViewCount
    FROM 
        Posts
),
CommentStats AS (
    SELECT 
        COUNT(*) AS TotalComments,
        AVG(Score) AS AverageCommentScore
    FROM 
        Comments
),
UserStats AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        AVG(Reputation) AS AverageUserReputation
    FROM 
        Users
)

SELECT 
    PS.TotalPosts,
    PS.AveragePostScore,
    PS.AverageViewCount,
    CS.TotalComments,
    CS.AverageCommentScore,
    US.TotalUsers,
    US.AverageUserReputation
FROM 
    PostStats PS, 
    CommentStats CS, 
    UserStats US;
