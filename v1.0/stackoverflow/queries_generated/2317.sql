WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1  -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    up.DisplayName,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges
FROM 
    RankedPosts rp
JOIN 
    Users up ON rp.OwnerUserId = up.Id
LEFT JOIN 
    UserBadges ub ON up.Id = ub.UserId
WHERE 
    rp.rn = 1  -- Get the most recent post for each user
ORDER BY 
    ub.GoldBadges DESC, 
    rp.Score DESC NULLS LAST
LIMIT 100;

-- Combining results with users who have never posted
UNION ALL

SELECT 
    u.DisplayName,
    NULL AS Title,
    NULL AS CreationDate,
    NULL AS ViewCount,
    NULL AS Score,
    COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
    COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
    COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    NOT EXISTS (
        SELECT 1 
        FROM Posts p 
        WHERE p.OwnerUserId = u.Id
    )
GROUP BY 
    u.DisplayName
ORDER BY 
    GoldBadges DESC
LIMIT 100;
