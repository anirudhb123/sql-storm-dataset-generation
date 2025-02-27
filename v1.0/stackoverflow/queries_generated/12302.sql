-- Performance Benchmarking Query
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(P.Views, 0)) AS TotalViews,
        SUM(COALESCE(P.AnswerCount, 0)) AS TotalAnswers,
        SUM(COALESCE(P.CommentCount, 0)) AS TotalComments
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
),

TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalScore,
        TotalViews,
        TotalAnswers,
        TotalComments,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM UserPostStats
)

SELECT 
    U.UserId,
    U.DisplayName,
    U.PostCount,
    U.TotalScore,
    U.TotalViews,
    U.TotalAnswers,
    U.TotalComments,
    U.ScoreRank
FROM TopUsers U
WHERE U.ScoreRank <= 10
ORDER BY U.TotalScore DESC;

-- Fetching total posts, users, and other aggregated data
SELECT 
    (SELECT COUNT(*) FROM Posts) AS TotalPosts,
    (SELECT COUNT(*) FROM Users) AS TotalUsers,
    (SELECT COUNT(*) FROM Comments) AS TotalComments,
    (SELECT COUNT(*) FROM Votes) AS TotalVotes,
    (SELECT COUNT(*) FROM Badges) AS TotalBadges;
