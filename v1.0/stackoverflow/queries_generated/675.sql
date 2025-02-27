WITH RankedUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM Users u
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(p.Id) AS TotalPosts,
        COUNT(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 END) AS AcceptedAnswers
    FROM Posts p
    GROUP BY p.OwnerUserId
),
TopUsers AS (
    SELECT 
        ru.Id,
        ru.DisplayName,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        ps.TotalViews,
        ps.TotalPosts,
        ps.AcceptedAnswers
    FROM RankedUsers ru
    LEFT JOIN UserBadges ub ON ru.Id = ub.UserId
    LEFT JOIN PostStats ps ON ru.Id = ps.OwnerUserId
    WHERE ru.Rank <= 10
)
SELECT 
    tu.DisplayName,
    COALESCE(tu.GoldBadges, 0) AS GoldBadges,
    COALESCE(tu.SilverBadges, 0) AS SilverBadges,
    COALESCE(tu.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(tu.TotalViews, 0) AS TotalViews,
    COALESCE(tu.TotalPosts, 0) AS TotalPosts,
    COALESCE(tu.AcceptedAnswers, 0) AS AcceptedAnswers,
    CASE 
        WHEN tu.TotalPosts IS NULL OR tu.TotalPosts = 0 THEN 'No Posts'
        ELSE FORMAT( (tu.AcceptedAnswers * 100.0 / tu.TotalPosts), 'N2') + '%' 
    END AS AcceptanceRate
FROM TopUsers tu
ORDER BY tu.TotalViews DESC;
