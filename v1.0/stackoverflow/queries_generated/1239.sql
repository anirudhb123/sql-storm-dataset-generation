WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostActivity AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '1 YEAR'
    GROUP BY p.OwnerUserId
),
UserPostStats AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.BadgeCount,
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges,
        COALESCE(pa.TotalPosts, 0) AS TotalPosts,
        COALESCE(pa.TotalQuestions, 0) AS TotalQuestions,
        COALESCE(pa.TotalAnswers, 0) AS TotalAnswers,
        COALESCE(pa.TotalViews, 0) AS TotalViews,
        COALESCE(pa.AverageScore, 0) AS AverageScore
    FROM UserStats us
    LEFT JOIN PostActivity pa ON us.UserId = pa.OwnerUserId
)
SELECT 
    ups.DisplayName,
    ups.Reputation,
    ups.BadgeCount,
    ups.GoldBadges,
    ups.SilverBadges,
    ups.BronzeBadges,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.TotalViews,
    ups.AverageScore,
    CASE 
        WHEN ups.Reputation >= 1000 THEN 'Veteran'
        WHEN ups.Reputation >= 500 THEN 'Experienced'
        ELSE 'Rookie'
    END AS ExperienceLevel,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagList
FROM UserPostStats ups
LEFT JOIN Posts p ON ups.UserId = p.OwnerUserId
LEFT JOIN Tags t ON t.Id IN (SELECT UNNEST(string_to_array(p.Tags, '>'))::int)
GROUP BY 
    ups.DisplayName, 
    ups.Reputation, 
    ups.BadgeCount,
    ups.GoldBadges, 
    ups.SilverBadges, 
    ups.BronzeBadges,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.TotalViews,
    ups.AverageScore
ORDER BY ups.Reputation DESC, ups.TotalPosts DESC
LIMIT 10;
