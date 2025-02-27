
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        SUM(ISNULL(p.Score, 0)) AS TotalScore,
        SUM(ISNULL(p.ViewCount, 0)) AS TotalViews,
        SUM(ISNULL(p.FavoriteCount, 0)) AS TotalFavorites
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
UserBadgeStats AS (
    SELECT 
        b.UserId,
        COUNT(*) AS TotalBadges,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
)

SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.TotalScore,
    ups.TotalViews,
    ups.TotalFavorites,
    ubs.TotalBadges,
    ubs.GoldBadges,
    ubs.SilverBadges,
    ubs.BronzeBadges
FROM UserPostStats ups
LEFT JOIN UserBadgeStats ubs ON ups.UserId = ubs.UserId
ORDER BY ups.TotalScore DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
