
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
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
        TotalViews,
        TotalBadges,
        @row_number := @row_number + 1 AS Ranking
    FROM 
        UserPostStats, (SELECT @row_number := 0) AS rn
    ORDER BY 
        TotalScore DESC
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalAnswers,
    tu.TotalQuestions,
    tu.TotalScore,
    tu.TotalViews,
    tu.TotalBadges,
    @rank := IF(@prev_total_views = tu.TotalViews, @rank, @rank + 1) AS ViewsRanking,
    @prev_total_views := tu.TotalViews
FROM 
    TopUsers tu, (SELECT @rank := 0, @prev_total_views := NULL) AS r
WHERE 
    tu.Ranking <= 10
ORDER BY 
    tu.Ranking, tu.TotalScore DESC;
