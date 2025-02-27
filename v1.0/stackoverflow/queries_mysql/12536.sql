
WITH PostStats AS (
    SELECT 
        DATE_FORMAT(CreationDate, '%Y-%m-01') AS Month,
        COUNT(*) AS TotalPosts,
        COUNT(DISTINCT OwnerUserId) AS UniquePostOwners
    FROM Posts
    GROUP BY DATE_FORMAT(CreationDate, '%Y-%m-01')
),
UserStats AS (
    SELECT 
        DATE_FORMAT(CreationDate, '%Y-%m-01') AS Month,
        COUNT(*) AS TotalUsers,
        SUM(Reputation) AS TotalReputation
    FROM Users
    GROUP BY DATE_FORMAT(CreationDate, '%Y-%m-01')
),
CommentStats AS (
    SELECT 
        DATE_FORMAT(CreationDate, '%Y-%m-01') AS Month,
        COUNT(*) AS TotalComments
    FROM Comments
    GROUP BY DATE_FORMAT(CreationDate, '%Y-%m-01')
),
VoteStats AS (
    SELECT 
        DATE_FORMAT(CreationDate, '%Y-%m-01') AS Month,
        COUNT(*) AS TotalVotes
    FROM Votes
    GROUP BY DATE_FORMAT(CreationDate, '%Y-%m-01')
)

SELECT 
    COALESCE(p.Month, u.Month, c.Month, v.Month) AS Month,
    COALESCE(TotalPosts, 0) AS TotalPosts,
    COALESCE(UniquePostOwners, 0) AS UniquePostOwners,
    COALESCE(TotalUsers, 0) AS TotalUsers,
    COALESCE(TotalReputation, 0) AS TotalReputation,
    COALESCE(TotalComments, 0) AS TotalComments,
    COALESCE(TotalVotes, 0) AS TotalVotes
FROM PostStats p
LEFT JOIN UserStats u ON p.Month = u.Month
LEFT JOIN CommentStats c ON p.Month = c.Month OR u.Month = c.Month
LEFT JOIN VoteStats v ON p.Month = v.Month OR u.Month = v.Month OR c.Month = v.Month
ORDER BY Month;
