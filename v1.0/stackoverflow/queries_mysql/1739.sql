
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
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
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        COUNT(p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ups.DisplayName,
    ups.TotalViews,
    ups.TotalScore,
    b.GoldBadges,
    b.SilverBadges,
    b.BronzeBadges,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score
FROM 
    UserPostStats ups
LEFT JOIN 
    UserBadges b ON ups.UserId = b.UserId
LEFT JOIN 
    RankedPosts rp ON ups.UserId = rp.OwnerUserId AND rp.rn = 1
WHERE 
    ups.TotalPosts > 0
ORDER BY 
    ups.TotalScore DESC, ups.TotalViews DESC
LIMIT 10;
