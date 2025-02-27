WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' AND
        p.ViewCount IS NOT NULL
), UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(b.Class = 1), 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2), 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges,
        COUNT(DISTINCT v.PostId) AS VoteCount,
        AVG(v.BountyAmount) AS AvgBounty
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.CreationDate < NOW() - INTERVAL '2 years'
    GROUP BY 
        u.Id
)
SELECT 
    us.DisplayName,
    up.PostId,
    up.Title,
    up.ViewCount,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    us.VoteCount,
    us.AvgBounty,
    CASE 
        WHEN up.rn = 1 THEN 'Top Post'
        ELSE 'Other Post'
    END AS PostRank
FROM 
    UserStats us
JOIN 
    RankedPosts up ON us.UserId = up.PostId
LEFT JOIN 
    Comments c ON up.PostId = c.PostId
WHERE 
    us.VoteCount > 5 AND 
    c.CreationDate IS NULL
ORDER BY 
    us.GoldBadges DESC, up.ViewCount DESC;
