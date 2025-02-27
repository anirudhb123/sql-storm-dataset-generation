
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE 
            WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE 
            WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE 
            WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        @row_number := IF(@current_user = p.OwnerUserId, @row_number + 1, 1) AS Pos,
        @current_user := p.OwnerUserId
    FROM 
        Posts p, (SELECT @row_number := 0, @current_user := NULL) AS r
    WHERE 
        p.CreationDate >= DATE_SUB('2024-10-01 12:34:56', INTERVAL 1 YEAR)
    ORDER BY 
        p.OwnerUserId, p.CreationDate DESC
)
SELECT 
    ub.UserId,
    ub.DisplayName,
    ub.TotalBadges,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount
FROM 
    UserBadges ub
JOIN 
    RecentPosts rp ON ub.UserId = rp.OwnerUserId
WHERE 
    rp.Pos <= 3  
ORDER BY 
    ub.TotalBadges DESC,
    rp.ViewCount DESC;
