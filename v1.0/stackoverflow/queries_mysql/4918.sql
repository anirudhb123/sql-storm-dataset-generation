
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE((SELECT COUNT(DISTINCT c.Id) 
                  FROM Comments c 
                  WHERE c.PostId = p.Id), 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 5
),
UserBadges AS (
    SELECT 
        b.UserId,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.TotalScore,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    p.Title,
    p.CommentCount,
    p.CreationDate,
    CASE 
        WHEN p.CommentCount > 10 THEN 'Highly Engaged'
        WHEN p.CommentCount BETWEEN 5 AND 10 THEN 'Moderately Engaged'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    TopUsers u
JOIN 
    RankedPosts p ON u.UserId = p.PostId
LEFT JOIN 
    UserBadges ub ON u.UserId = ub.UserId
WHERE 
    p.RN = 1
ORDER BY 
    u.TotalScore DESC, 
    p.CreationDate DESC
LIMIT 100;
