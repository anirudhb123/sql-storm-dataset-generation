
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
        p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56') AND
        p.ViewCount IS NOT NULL
), UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges,
        COUNT(DISTINCT v.PostId) AS VoteCount,
        AVG(v.BountyAmount) AS AvgBounty
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.CreationDate < DATEADD(year, -2, '2024-10-01 12:34:56')
    GROUP BY 
        u.Id, u.DisplayName
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
