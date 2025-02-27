
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
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
        @rank := @rank + 1 AS Rank
    FROM 
        UserPostStats, (SELECT @rank := 0) r
    ORDER BY 
        TotalScore DESC
)
SELECT 
    Rank,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalViews,
    TotalScore
FROM 
    TopUsers
WHERE 
    Rank <= 10;
