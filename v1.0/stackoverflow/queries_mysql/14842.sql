
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS TotalPosts,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
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
        TotalPosts, 
        TotalQuestions, 
        TotalAnswers, 
        TotalScore, 
        TotalViews,
        @rownum := @rownum + 1 AS ScoreRank
    FROM 
        UserPostStats, (SELECT @rownum := 0) r
    ORDER BY 
        TotalScore DESC
)
SELECT 
    u.DisplayName,
    t.TotalPosts,
    t.TotalQuestions,
    t.TotalAnswers,
    t.TotalScore,
    t.TotalViews,
    t.ScoreRank
FROM 
    TopUsers t
JOIN 
    Users u ON t.UserId = u.Id
WHERE 
    t.ScoreRank <= 10
ORDER BY 
    t.TotalScore DESC;
