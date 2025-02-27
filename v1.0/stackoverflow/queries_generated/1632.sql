WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate ASC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
), UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
), PopularUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COALESCE(u.Views, 0) + COALESCE(ub.GoldBadges * 100, 0) + COALESCE(ub.SilverBadges * 50, 0) + COALESCE(ub.BronzeBadges * 25, 0) AS EngagementScore
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    WHERE 
        u.Reputation > 100
)
SELECT 
    pu.DisplayName,
    COUNT(rp.PostId) AS PostCount,
    SUM(rp.Score) AS TotalScore,
    SUM(rp.ViewCount) AS TotalViews,
    pu.EngagementScore
FROM 
    RankedPosts rp
JOIN 
    PopularUsers pu ON rp.OwnerUserId = pu.Id
WHERE 
    rp.rn <= 5
GROUP BY 
    pu.DisplayName, pu.EngagementScore
HAVING 
    SUM(rp.Score) > 50
ORDER BY 
    EngagementScore DESC, TotalScore DESC;
