WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year' 
        AND p.PostTypeId = 1 
        AND p.Score > 10
),
UserAggregates AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(v.BountyAmount) AS TotalBounty,
        COALESCE(SUM(b.Class = 1)::int, 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2)::int, 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3)::int, 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)
    LEFT JOIN 
        Badges b ON u.Id = b.UserId 
    GROUP BY 
        u.Id
)
SELECT 
    ua.DisplayName,
    ua.PostCount,
    ua.TotalBounty,
    ua.GoldBadges,
    ua.SilverBadges,
    ua.BronzeBadges,
    rp.Title AS LatestPostTitle,
    rp.CreationDate AS LatestPostDate
FROM 
    UserAggregates ua
LEFT JOIN 
    RankedPosts rp ON ua.UserId = rp.OwnerUserId AND rp.rn = 1
WHERE 
    ua.PostCount > 0
ORDER BY 
    ua.TotalBounty DESC, 
    ua.PostCount DESC
FETCH FIRST 10 ROWS ONLY;
