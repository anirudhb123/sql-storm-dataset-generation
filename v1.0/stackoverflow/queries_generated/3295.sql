WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(b.Class = 1)::int, 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2)::int, 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3)::int, 0) AS BronzeBadges,
        u.Reputation,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    rp.Title,
    rp.CreationDate,
    rp.CommentCount
FROM 
    UserStatistics us
JOIN 
    RankedPosts rp ON us.UserId = rp.PostRank
WHERE 
    rp.PostRank = 1
    AND us.Reputation >= 1000
    AND (us.GoldBadges > 0 OR us.SilverBadges > 5)
ORDER BY 
    us.Reputation DESC, rp.CreationDate ASC
LIMIT 10;
