mysql
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalPosts, 
        TotalQuestions, 
        TotalAnswers, 
        TotalScore,
        @rank := IF(@prevScore = TotalScore, @rank, @rank + 1) AS Rank,
        @prevScore := TotalScore
    FROM 
        UserPostStats, (SELECT @rank := 0, @prevScore := NULL) r
    ORDER BY 
        TotalScore DESC
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalScore
FROM 
    TopUsers
WHERE 
    Rank <= 10;
