-- Performance Benchmarking Query
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(VIEWCOUNT) AS AvgViewCount,
        AVG(Score) AS AvgScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        AvgViewCount,
        AvgScore,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM 
        UserPostStats
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    AvgViewCount,
    AvgScore,
    PostRank
FROM 
    TopUsers
WHERE 
    PostRank <= 10
ORDER BY 
    PostRank;
