
WITH UserPosts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.ViewCount) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
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
        TotalViews,
        TotalScore,
        @rankScore := IF(@prevScore = TotalScore, @rankScore, @rowNum) AS RankScore,
        @prevScore := TotalScore,
        @rowNum := @rowNum + 1 AS Row
    FROM 
        UserPosts, (SELECT @rankScore := 0, @prevScore := NULL, @rowNum := 0) AS vars
    ORDER BY 
        TotalScore DESC
)
SELECT 
    u.DisplayName,
    tu.TotalPosts,
    tu.TotalQuestions,
    tu.TotalAnswers,
    tu.TotalViews,
    tu.TotalScore,
    tu.RankScore,
    (SELECT COUNT(*) FROM UserPosts WHERE TotalViews > tu.TotalViews) + 1 AS RankViews
FROM 
    TopUsers tu
JOIN 
    Users u ON tu.UserId = u.Id
WHERE 
    tu.TotalPosts > 0
ORDER BY 
    tu.RankScore, tu.RankViews;
