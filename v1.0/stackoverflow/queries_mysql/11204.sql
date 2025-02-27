
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS TotalAnswers,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
),

TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalViews,
        TotalScore,
        @Rank := @Rank + 1 AS Rank
    FROM UserPostStats, (SELECT @Rank := 0) AS r
    ORDER BY TotalScore DESC
)

SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalViews,
    TotalScore,
    Rank
FROM TopUsers
WHERE Rank <= 10;
