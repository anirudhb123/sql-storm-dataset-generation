WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) as Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u 
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    up.DisplayName,
    COUNT(DISTINCT rp.PostId) AS TotalPosts,
    SUM(rp.Score) AS TotalScore,
    ub.BadgeCount,
    ub.HighestBadgeClass
FROM 
    RankedPosts rp
JOIN 
    Users up ON rp.OwnerUserId = up.Id
LEFT JOIN 
    UserBadges ub ON up.Id = ub.UserId
WHERE 
    rp.Rank <= 5
GROUP BY 
    up.DisplayName, ub.BadgeCount, ub.HighestBadgeClass
HAVING 
    SUM(rp.Score) > 100
ORDER BY 
    TotalScore DESC;
