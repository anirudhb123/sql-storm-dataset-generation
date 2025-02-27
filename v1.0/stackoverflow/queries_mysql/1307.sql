
WITH UserBadges AS (
    SELECT 
        b.UserId, 
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
RecentPosts AS (
    SELECT 
        p.Id,
        p.OwnerUserId,
        p.Title,
        p.Score,
        p.CreationDate,
        @rn := IF(@prevOwnerUserId = p.OwnerUserId, @rn + 1, 1) AS rn,
        @prevOwnerUserId := p.OwnerUserId
    FROM 
        Posts p
    JOIN (SELECT @rn := 0, @prevOwnerUserId := NULL) AS vars
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 30 DAY
    ORDER BY 
        p.OwnerUserId, p.CreationDate DESC
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(ub.BadgeCount, 0) AS TotalBadges,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    rp.Title AS RecentPostTitle,
    rp.Score AS RecentPostScore,
    rp.CreationDate AS RecentPostDate
FROM 
    Users u
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    RecentPosts rp ON u.Id = rp.OwnerUserId AND rp.rn = 1
WHERE 
    u.Reputation >= 1000
ORDER BY 
    u.Reputation DESC
LIMIT 10;
