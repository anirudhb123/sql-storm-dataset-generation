WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RN
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
    GROUP BY 
        p.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
    HAVING 
        SUM(b.Class) > 0
),
FinalResult AS (
    SELECT 
        rp.Title,
        rp.Score,
        rp.CommentCount,
        uu.DisplayName,
        uu.GoldBadges,
        uu.SilverBadges,
        uu.BronzeBadges
    FROM 
        RankedPosts rp
    JOIN 
        TopUsers uu ON rp.OwnerUserId = uu.UserId
    WHERE 
        rp.RN <= 5
)
SELECT 
    fr.Title,
    fr.Score,
    fr.CommentCount,
    fr.DisplayName,
    COALESCE(fr.GoldBadges, 0) AS GoldBadgeCount,
    COALESCE(fr.SilverBadges, 0) AS SilverBadgeCount,
    COALESCE(fr.BronzeBadges, 0) AS BronzeBadgeCount
FROM 
    FinalResult fr
ORDER BY 
    fr.Score DESC, 
    fr.CommentCount DESC;

