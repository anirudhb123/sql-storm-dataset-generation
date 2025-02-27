
WITH PostStats AS (
    SELECT 
        DATEADD(month, DATEDIFF(month, 0, CreationDate), 0) AS Month,
        COUNT(*) AS TotalPosts,
        COUNT(DISTINCT OwnerUserId) AS UniquePostOwners
    FROM Posts
    GROUP BY DATEADD(month, DATEDIFF(month, 0, CreationDate), 0)
),
UserStats AS (
    SELECT 
        DATEADD(month, DATEDIFF(month, 0, CreationDate), 0) AS Month,
        COUNT(*) AS TotalUsers,
        SUM(Reputation) AS TotalReputation
    FROM Users
    GROUP BY DATEADD(month, DATEDIFF(month, 0, CreationDate), 0)
),
CommentStats AS (
    SELECT 
        DATEADD(month, DATEDIFF(month, 0, CreationDate), 0) AS Month,
        COUNT(*) AS TotalComments
    FROM Comments
    GROUP BY DATEADD(month, DATEDIFF(month, 0, CreationDate), 0)
),
VoteStats AS (
    SELECT 
        DATEADD(month, DATEDIFF(month, 0, CreationDate), 0) AS Month,
        COUNT(*) AS TotalVotes
    FROM Votes
    GROUP BY DATEADD(month, DATEDIFF(month, 0, CreationDate), 0)
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
FULL OUTER JOIN UserStats u ON p.Month = u.Month
FULL OUTER JOIN CommentStats c ON p.Month = c.Month OR u.Month = c.Month
FULL OUTER JOIN VoteStats v ON p.Month = v.Month OR u.Month = v.Month OR c.Month = v.Month
ORDER BY Month;
