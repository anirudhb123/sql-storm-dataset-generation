WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(b.Class = 1), 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2), 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.PostCount,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    up.Id AS TopPostId,
    up.Title AS TopPostTitle,
    up.CreationDate AS TopPostDate,
    up.Score AS TopPostScore,
    up.ViewCount AS TopPostViews,
    CASE 
        WHEN up.Id IS NULL THEN 'No posts found'
        ELSE 'Top post retrieved'
    END AS PostStatus
FROM 
    UserStats us
LEFT JOIN 
    RankedPosts up ON us.UserId = up.OwnerUserId AND up.PostRank = 1
ORDER BY 
    us.PostCount DESC,
    us.UserId;
