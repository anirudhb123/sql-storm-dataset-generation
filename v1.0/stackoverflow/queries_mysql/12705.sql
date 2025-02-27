
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
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
        AvgViewCount,
        @row_number := @row_number + 1 AS ScoreRank
    FROM UserPostStats, (SELECT @row_number := 0) AS r
    ORDER BY TotalScore DESC
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalScore,
    AvgViewCount
FROM TopUsers
WHERE ScoreRank <= 10;
