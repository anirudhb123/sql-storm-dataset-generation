-- Query to benchmark performance by counting posts, users, comments, and votes
-- and getting average times for post creation and user account creation.

WITH UserStats AS (
    SELECT 
        COUNT(*) AS TotalUsers,
        AVG(DATEDIFF(SECOND, CreationDate, GETDATE())) AS AvgUserAgeInSeconds
    FROM 
        Users
),
PostStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        AVG(DATEDIFF(SECOND, CreationDate, GETDATE())) AS AvgPostAgeInSeconds
    FROM 
        Posts
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
