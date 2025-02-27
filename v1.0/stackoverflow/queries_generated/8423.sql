WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.PostTypeId = 1
), UserBadges AS (
    SELECT 
        ub.UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    JOIN 
        Users ub ON b.UserId = ub.Id
    GROUP BY 
        ub.UserId
), PostTypesCount AS (
    SELECT 
        p.OwnerUserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        AVG(p.Score) AS AvgScore
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (2, 1) 
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    ub.BadgeCount AS TotalBadges,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    COALESCE(rt.PostCount, 0) AS TotalPosts,
    COALESCE(rt.AvgScore, 0) AS AverageScore,
    COUNT(rp.PostId) AS TopPostsCount,
    MAX(rp.Score) AS MaxPostScore,
    MIN(rp.CreationDate) AS EarliestPostDate
FROM 
    Users u
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerDisplayName
LEFT JOIN 
    PostTypesCount rt ON u.Id = rt.OwnerUserId
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.Id, ub.BadgeCount, ub.GoldBadges, ub.SilverBadges, ub.BronzeBadges, rt.PostCount, rt.AvgScore
ORDER BY 
    TotalPosts DESC, AverageScore DESC
LIMIT 50;
