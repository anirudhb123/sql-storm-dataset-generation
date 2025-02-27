WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank,
        COALESCE(pc.CommentCount, 0) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) pc ON p.Id = pc.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserAchievements AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
)
SELECT 
    u.DisplayName,
    u.Reputation,
    ra.PostId,
    ra.Title,
    ra.Score,
    ra.CreationDate,
    ua.BadgeCount,
    ua.GoldBadges,
    ua.SilverBadges,
    ua.BronzeBadges
FROM 
    Users u
JOIN 
    RankedPosts ra ON u.Id = ra.OwnerUserId
JOIN 
    UserAchievements ua ON u.Id = ua.UserId
WHERE 
    ra.ScoreRank <= 5 
    AND (ua.BadgeCount > 0 OR u.Reputation > 1000)
ORDER BY 
    ua.BadgeCount DESC, ra.Score DESC
LIMIT 20;
