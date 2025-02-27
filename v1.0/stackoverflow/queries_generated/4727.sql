WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    AND 
        p.Score > 0
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    up.DisplayName,
    up.UserId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    COALESCE(SUM(CASE WHEN c.Score > 0 THEN c.Score END), 0) AS TotalCommentScore,
    COALESCE((SELECT COUNT(*) FROM Comments cm WHERE cm.PostId = rp.Id), 0) AS CommentCount,
    (SELECT string_agg(DISTINCT t.TagName, ', ') 
     FROM unnest(string_to_array(p.Tags, '<>')) AS t) AS TagsUsed
FROM 
    RankedPosts rp
JOIN 
    Users up ON rp.OwnerUserId = up.Id
LEFT JOIN 
    UserBadges ub ON up.Id = ub.UserId
LEFT JOIN 
    Comments c ON c.PostId = rp.Id
WHERE 
    rp.rn = 1 
GROUP BY 
    up.UserId, rp.Title, rp.CreationDate, rp.Score, ub.GoldBadges, ub.SilverBadges, ub.BronzeBadges
ORDER BY 
    rp.Score DESC
LIMIT 50
OFFSET 100;
