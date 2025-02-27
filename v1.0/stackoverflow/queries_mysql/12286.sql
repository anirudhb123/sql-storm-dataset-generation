
WITH UserPostStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS TotalPositivePosts,
        AVG(p.Score) AS AverageScore,
        AVG(p.ViewCount) AS AverageViewCount
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
        TotalPositivePosts,
        AverageScore,
        AverageViewCount,
        @row_number := @row_number + 1 AS Rank
    FROM UserPostStats, (SELECT @row_number := 0) AS r
    ORDER BY TotalPosts DESC
)
SELECT
    UserId,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalPositivePosts,
    AverageScore,
    AverageViewCount
FROM TopUsers
WHERE Rank <= 10;
