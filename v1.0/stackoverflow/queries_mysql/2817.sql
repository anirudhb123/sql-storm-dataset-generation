
WITH UserBadges AS (
    SELECT 
        ub.UserId,
        COUNT(CASE WHEN ub.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN ub.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN ub.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges ub
    GROUP BY ub.UserId
),
RecentPosts AS (
    SELECT 
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        @rn := IF(@prevOwnerUserId = p.OwnerUserId, @rn + 1, 1) AS rn,
        @prevOwnerUserId := p.OwnerUserId
    FROM Posts p, (SELECT @rn := 0, @prevOwnerUserId := NULL) AS vars
    WHERE p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 30 DAY
    ORDER BY p.OwnerUserId, p.CreationDate DESC
),
PostMetrics AS (
    SELECT 
        rp.OwnerUserId,
        COUNT(*) AS RecentPostCount,
        SUM(rp.ViewCount) AS TotalViews
    FROM RecentPosts rp
    WHERE rp.rn <= 5
    GROUP BY rp.OwnerUserId
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(pm.RecentPostCount, 0) AS RecentPostCount,
        COALESCE(pm.TotalViews, 0) AS TotalViews
    FROM Users u
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN PostMetrics pm ON u.Id = pm.OwnerUserId
)
SELECT 
    us.UserId,
    us.Reputation,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    us.RecentPostCount,
    us.TotalViews,
    RANK() OVER (ORDER BY us.Reputation DESC) AS ReputationRank
FROM UserScores us
WHERE us.Reputation > 1000
  AND us.RecentPostCount > 0
ORDER BY us.TotalViews DESC
LIMIT 10;
