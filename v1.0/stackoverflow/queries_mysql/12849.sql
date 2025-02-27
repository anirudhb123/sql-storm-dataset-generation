
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
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
        TotalAnswers,
        TotalQuestions,
        TotalScore,
        @row_num := @row_num + 1 AS Rank
    FROM 
        UserPostStats, (SELECT @row_num := 0) AS r
    ORDER BY 
        TotalScore DESC
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalAnswers,
    TotalQuestions,
    TotalScore
FROM 
    TopUsers
WHERE 
    Rank <= 10;
