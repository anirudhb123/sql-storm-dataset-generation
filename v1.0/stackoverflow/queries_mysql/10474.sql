
WITH UserPostStats AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(Posts.Id) AS TotalPosts,
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(Posts.ViewCount) AS TotalViews,
        SUM(Posts.Score) AS TotalScore
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    GROUP BY 
        Users.Id, Users.DisplayName
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
        @rank := IF(@prev_score = TotalScore, @rank, @rank + 1) AS ScoreRank,
        @prev_score := TotalScore
    FROM 
        UserPostStats, 
        (SELECT @rank := 0, @prev_score := NULL) AS vars
    ORDER BY 
        TotalScore DESC
)
SELECT 
    UserId, 
    DisplayName, 
    TotalPosts, 
    TotalQuestions, 
    TotalAnswers, 
    TotalViews, 
    TotalScore, 
    ScoreRank
FROM 
    TopUsers
WHERE 
    ScoreRank <= 10
ORDER BY 
    ScoreRank;
