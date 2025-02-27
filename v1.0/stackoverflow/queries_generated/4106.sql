WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) -- Posts in the last year
),
UserBadges AS (
    SELECT 
        b.UserId,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    rb.PostId,
    rb.Title,
    rb.Score,
    rb.CreationDate,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    rb.CommentCount,
    CASE 
        WHEN rb.Score > 100 THEN 'High Score'
        WHEN rb.Score BETWEEN 50 AND 100 THEN 'Moderate Score'
        ELSE 'Low Score'
    END AS ScoreCategory,
    COALESCE(NULLIF(ub.GoldBadges, 0), -1) AS EffectiveGoldBadges
FROM 
    Users u
INNER JOIN 
    RankedPosts rb ON u.Id = rb.PostRank
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    rb.PostRank = 1 -- Select latest post per user
ORDER BY 
    u.Reputation DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
