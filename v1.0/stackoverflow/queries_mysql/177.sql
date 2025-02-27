
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        @row_number := IF(@current_owner = p.OwnerUserId, @row_number + 1, 1) AS Rank,
        @current_owner := p.OwnerUserId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    CROSS JOIN (SELECT @row_number := 0, @current_owner := NULL) AS vars
    WHERE 
        p.CreationDate > NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
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
    COUNT(DISTINCT rp.Id) AS TotalPosts,
    SUM(rp.Score) AS TotalScore,
    MAX(rp.ViewCount) AS MostViewedPost,
    ub.BadgeCount,
    ub.HighestBadgeClass
FROM 
    RankedPosts rp
JOIN 
    Users up ON rp.OwnerUserId = up.Id
JOIN 
    UserBadges ub ON up.Id = ub.UserId
WHERE 
    ub.BadgeCount > 0 AND rp.Rank <= 3
GROUP BY 
    up.DisplayName, ub.BadgeCount, ub.HighestBadgeClass
ORDER BY 
    TotalScore DESC, TotalPosts DESC
LIMIT 10;
