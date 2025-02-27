
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AverageViewCount
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
        TotalScore,
        AverageViewCount,
        @rank := IF(@prev_score = TotalScore, @rank, @rank + 1) AS ScoreRank,
        @prev_score := TotalScore
    FROM UserPostStats, (SELECT @rank := 0, @prev_score := NULL) AS vars
    ORDER BY TotalScore DESC
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalScore,
    AverageViewCount
FROM TopUsers
WHERE ScoreRank <= 10  
ORDER BY TotalScore DESC;
