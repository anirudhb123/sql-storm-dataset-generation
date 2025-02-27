
WITH UserStats AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        AVG(DATEDIFF(SECOND, CreationDate, CURRENT_TIMESTAMP)) AS AvgUserAgeInSeconds
    FROM 
        Users
    GROUP BY 
        CreationDate
),
PostStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        AVG(DATEDIFF(SECOND, CreationDate, CURRENT_TIMESTAMP)) AS AvgPostAgeInSeconds
    FROM 
        Posts
    GROUP BY 
        CreationDate
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
    u.TotalUsers,
    u.AvgUserAgeInSeconds,
    p.TotalPosts,
    p.AvgPostAgeInSeconds,
    c.TotalComments,
    v.TotalVotes
FROM 
    UserStats u,
    PostStats p,
    CommentStats c,
    VoteStats v;
