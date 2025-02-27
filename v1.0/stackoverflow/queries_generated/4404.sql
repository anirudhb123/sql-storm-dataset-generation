WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.ViewCount, 
        p.CreationDate, 
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
), 
UserBadges AS (
    SELECT 
        b.UserId, 
        COUNT(b.Id) AS BadgeCount, 
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
    COUNT(DISTINCT p.Id) AS TotalPosts, 
    COALESCE(ub.BadgeCount, 0) AS TotalBadges, 
    COALESCE(ub.GoldBadges, 0) AS GoldBadges, 
    p.Title AS TopPostTitle,
    p.ViewCount AS TopPostViewCount
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId) AND rp.ViewRank = 1
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.Id, ub.BadgeCount, ub.GoldBadges, ub.SilverBadges, ub.BronzeBadges, p.Title, p.ViewCount
ORDER BY 
    TotalPosts DESC, u.DisplayName;
