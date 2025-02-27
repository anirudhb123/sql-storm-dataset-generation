
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN p.ViewCount ELSE 0 END) AS TotalQuestionViews,
        AVG(p.Score) AS AvgScore,
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
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalQuestionViews,
        AvgScore,
        TotalComments,
        @row_num := @row_num + 1 AS Rank
    FROM 
        UserPostStats, (SELECT @row_num := 0) AS r
    ORDER BY TotalPosts DESC
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalQuestionViews,
    AvgScore,
    TotalComments
FROM 
    TopUsers
WHERE 
    Rank <= 10;
