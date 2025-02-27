WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (CURRENT_DATE - INTERVAL '1 year')
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(*) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(*) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
)
SELECT 
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    t.DisplayName AS TopUser,
    t.GoldBadges,
    t.SilverBadges,
    t.BronzeBadges,
    p.CommentCount
FROM 
    RankedPosts p
JOIN 
    TopUsers t ON p.ViewCount > 100 AND p.CommentCount > 0 AND t.UserRank <= 10
WHERE 
    p.PostRank = 1
ORDER BY 
    p.Score DESC
LIMIT 50
UNION ALL
SELECT 
    'No top posts found' AS Title,
    CURRENT_TIMESTAMP AS CreationDate,
    0 AS ViewCount,
    0 AS Score,
    NULL AS TopUser,
    0 AS GoldBadges,
    0 AS SilverBadges,
    0 AS BronzeBadges,
    0 AS CommentCount
WHERE NOT EXISTS (SELECT 1 FROM RankedPosts)
ORDER BY 
    CreationDate DESC;
