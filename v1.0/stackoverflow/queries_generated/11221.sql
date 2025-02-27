-- Performance Benchmarking Query Example
-- This query retrieves user stats and post details for performance analysis

WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        COALESCE(SUM(p.FavoriteCount), 0) AS TotalFavorites
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
)

SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.Reputation,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.TotalScore,
    ups.TotalViews,
    ups.TotalFavorites,
    (SELECT COUNT(*) FROM Badges b WHERE b.UserId = ups.UserId) AS BadgeCount
FROM 
    UserPostStats ups
ORDER BY 
    ups.Reputation DESC, 
    ups.TotalScore DESC
LIMIT 100; -- Limiting results for performance testing
