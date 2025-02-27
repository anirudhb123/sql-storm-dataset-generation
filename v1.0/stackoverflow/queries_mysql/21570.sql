
WITH UserBadges AS (
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
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(IFNULL(p.ViewCount, 0)) AS TotalViews,
        SUM(IFNULL(p.Score, 0)) AS TotalScore,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers
    FROM Posts p
    GROUP BY p.OwnerUserId
),
RecentActivity AS (
    SELECT 
        p.OwnerUserId,
        MAX(p.LastActivityDate) AS LastActive
    FROM Posts p
    WHERE p.LastActivityDate IS NOT NULL
    GROUP BY p.OwnerUserId
),
QualifiedUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        IFNULL(ub.GoldBadges, 0) + IFNULL(ub.SilverBadges, 0) + IFNULL(ub.BronzeBadges, 0) AS TotalBadges,
        ps.TotalPosts,
        ps.TotalViews,
        ps.TotalScore,
        ra.LastActive
    FROM Users u
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
    LEFT JOIN RecentActivity ra ON u.Id = ra.OwnerUserId
    WHERE 
        u.Reputation > 100
        AND (
            (ps.TotalQuestions > 5 AND ps.TotalAnswers > 10)
            OR (ub.GoldBadges > 0)
        )
)
SELECT 
    q.DisplayName,
    q.TotalBadges,
    IFNULL(q.TotalPosts, 0) AS TotalPosts,
    IFNULL(q.TotalViews, 0) AS TotalViews,
    IFNULL(q.TotalScore, 0) AS TotalScore,
    q.LastActive,
    CASE 
        WHEN q.LastActive IS NULL THEN 'Never Active'
        WHEN q.LastActive < NOW() - INTERVAL 1 YEAR THEN 'Inactive for over a year'
        ELSE 'Active Recently'
    END AS ActivityStatus
FROM QualifiedUsers q
ORDER BY 
    q.TotalBadges DESC, 
    q.TotalScore DESC,
    q.LastActive DESC;
