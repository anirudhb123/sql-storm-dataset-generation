
WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(CASE WHEN b.Class = 1 THEN b.Id END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN b.Id END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN b.Id END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.AnswerCount,
        p.CommentCount,
        p.Score,
        @rn := IF(@prev = p.OwnerUserId, @rn + 1, 1) AS rn,
        @prev := p.OwnerUserId
    FROM 
        Posts p,
        (SELECT @rn := 0, @prev := NULL) AS vars
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 MONTH
    ORDER BY 
        p.OwnerUserId, p.CreationDate DESC
)
SELECT 
    u.DisplayName,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.AnswerCount,
    rp.CommentCount,
    rp.Score
FROM 
    Users u
LEFT JOIN 
    UserBadgeCounts ub ON u.Id = ub.UserId
LEFT JOIN 
    RecentPosts rp ON u.Id = rp.OwnerUserId 
WHERE 
    u.Reputation > 1000
    AND rp.rn = 1
ORDER BY 
    u.Reputation DESC, 
    rp.CreationDate DESC;
