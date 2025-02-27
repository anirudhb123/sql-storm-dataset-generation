
WITH UserPostStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AvgScorePerPost,
        AVG(p.ViewCount) AS AvgViewsPerPost
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE u.Reputation > 0 
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalScore,
        TotalViews,
        AvgScorePerPost,
        AvgViewsPerPost,
        (SELECT COUNT(*) FROM UserPostStats ups WHERE ups.TotalScore > ups2.TotalScore) + 1 AS ScoreRank
    FROM UserPostStats ups2
)

SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalScore,
    TotalViews,
    AvgScorePerPost,
    AvgViewsPerPost
FROM TopUsers
WHERE ScoreRank <= 10;
