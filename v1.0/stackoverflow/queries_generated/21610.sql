WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadgeCount,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadgeCount,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        AVG(COALESCE(p.Score, 0)) OVER (PARTITION BY p.OwnerUserId) AS AvgScore,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY p.OwnerUserId
),
ClosedPostStats AS (
    SELECT 
        ph.UserId,
        COUNT(ph.Id) AS ClosedPostCount,
        MIN(ph.CreationDate) AS FirstCloseDate,
        ARRAY_AGG(DISTINCT ph.PostId) AS ClosedPostIds
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.UserId
),
UsersOverallStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ub.GoldBadgeCount, 0) AS GoldBadges,
        COALESCE(ub.SilverBadgeCount, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadgeCount, 0) AS BronzeBadges,
        COALESCE(ps.PostCount, 0) AS TotalPosts,
        COALESCE(ps.TotalViews, 0) AS TotalViews,
        COALESCE(ps.TotalScore, 0) AS TotalScore,
        COALESCE(ps.AvgScore, 0) AS AvgScore,
        COALESCE(cs.ClosedPostCount, 0) AS ClosedPosts,
        cs.FirstCloseDate,
        cs.ClosedPostIds 
    FROM Users u
    LEFT JOIN UserBadgeCounts ub ON u.Id = ub.UserId
    LEFT JOIN PostStatistics ps ON u.Id = ps.OwnerUserId
    LEFT JOIN ClosedPostStats cs ON u.Id = cs.UserId
)
SELECT 
    UserId,
    DisplayName,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    TotalPosts,
    TotalViews,
    TotalScore,
    AvgScore,
    ClosedPosts,
    COALESCE(FirstCloseDate, 'No Closures') AS FirstCloseDate,
    CASE 
        WHEN ClosedPostIds IS NOT NULL THEN 
            (SELECT STRING_AGG(CAST(x AS TEXT), ', ') 
             FROM UNNEST(ClosedPostIds) AS x)
        ELSE 
            'No Closed Posts'
    END AS ClosedPostIds
FROM UsersOverallStats
WHERE TotalPosts > 10 AND (GoldBadges + SilverBadges + BronzeBadges) > 0
ORDER BY TotalScore DESC NULLS LAST
LIMIT 100;
