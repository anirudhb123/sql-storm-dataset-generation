WITH UserBadgeStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY COUNT(b.Id) DESC) AS BadgeRank
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
)
SELECT 
    ub.DisplayName,
    ub.TotalBadges,
    pp.Title,
    pp.Score,
    pp.ViewCount
FROM 
    UserBadgeStats ub
JOIN 
    PopularPosts pp ON ub.UserId = p.OwnerUserId
WHERE 
    ub.BadgeRank <= 10 AND pp.PostRank <= 20
ORDER BY 
    ub.TotalBadges DESC, pp.Score DESC;
