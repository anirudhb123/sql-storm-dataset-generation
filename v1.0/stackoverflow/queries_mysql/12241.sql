
WITH PostStats AS (
    SELECT 
        DATE_FORMAT(CreationDate, '%Y-%m-01') AS Month,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
    FROM Posts
    GROUP BY DATE_FORMAT(CreationDate, '%Y-%m-01')
),
VoteStats AS (
    SELECT 
        DATE_FORMAT(CreationDate, '%Y-%m-01') AS Month,
        COUNT(*) AS TotalVotes
    FROM Votes
    GROUP BY DATE_FORMAT(CreationDate, '%Y-%m-01')
),
UserStats AS (
    SELECT 
        DATE_FORMAT(CreationDate, '%Y-%m-01') AS Month,
        COUNT(*) AS TotalUsers
    FROM Users
    GROUP BY DATE_FORMAT(CreationDate, '%Y-%m-01')
)
SELECT 
    COALESCE(p.Month, v.Month, u.Month) AS Month,
    COALESCE(p.TotalPosts, 0) AS TotalPosts,
    COALESCE(p.TotalQuestions, 0) AS TotalQuestions,
    COALESCE(p.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(v.TotalVotes, 0) AS TotalVotes,
    COALESCE(u.TotalUsers, 0) AS TotalUsers
FROM PostStats p
LEFT JOIN VoteStats v ON p.Month = v.Month
LEFT JOIN UserStats u ON p.Month = u.Month
UNION 
SELECT 
    COALESCE(p.Month, v.Month, u.Month) AS Month,
    COALESCE(p.TotalPosts, 0) AS TotalPosts,
    COALESCE(p.TotalQuestions, 0) AS TotalQuestions,
    COALESCE(p.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(v.TotalVotes, 0) AS TotalVotes,
    COALESCE(u.TotalUsers, 0) AS TotalUsers
FROM VoteStats v
LEFT JOIN PostStats p ON p.Month = v.Month
LEFT JOIN UserStats u ON v.Month = u.Month
WHERE p.Month IS NULL
UNION 
SELECT 
    COALESCE(p.Month, v.Month, u.Month) AS Month,
    COALESCE(p.TotalPosts, 0) AS TotalPosts,
    COALESCE(p.TotalQuestions, 0) AS TotalQuestions,
    COALESCE(p.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(v.TotalVotes, 0) AS TotalVotes,
    COALESCE(u.TotalUsers, 0) AS TotalUsers
FROM UserStats u
LEFT JOIN PostStats p ON p.Month = u.Month
LEFT JOIN VoteStats v ON u.Month = v.Month
WHERE p.Month IS NULL AND v.Month IS NULL
ORDER BY Month;
