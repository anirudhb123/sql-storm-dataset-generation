
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(p.Score) AS AveragePostScore,
        SUM(p.ViewCount) AS TotalViewCount,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
ActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        AveragePostScore,
        TotalViewCount,
        TotalComments
    FROM 
        UserPostStats
    WHERE 
        TotalPosts > 0
)
SELECT 
    @row_number := @row_number + 1 AS Rank,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    AveragePostScore,
    TotalViewCount,
    TotalComments
FROM 
    ActiveUsers, (SELECT @row_number := 0) AS rn
ORDER BY 
    TotalPosts DESC;
