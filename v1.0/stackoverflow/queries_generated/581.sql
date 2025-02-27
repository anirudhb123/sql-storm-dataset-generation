WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(ph.Comment, 'No comments') AS LastHistoryComment,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.CreationDate = (
            SELECT MAX(CreationDate) 
            FROM PostHistory 
            WHERE PostId = p.Id
        )
    WHERE 
        p.ViewCount > 100
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    SUM(CASE WHEN bp.PostRank = 1 THEN 1 ELSE 0 END) AS RecentPostsCount,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges
FROM 
    Users u
LEFT JOIN 
    RankedPosts bp ON u.Id = bp.OwnerUserId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
GROUP BY 
    u.Id, u.DisplayName, ub.BadgeCount, ub.GoldBadges, ub.SilverBadges, ub.BronzeBadges
HAVING 
    COUNT(bp.PostId) > 5 
ORDER BY 
    ub.BadgeCount DESC, RecentPostsCount DESC;
