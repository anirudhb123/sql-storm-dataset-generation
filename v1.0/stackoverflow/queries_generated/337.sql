WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    up.UserId,
    u.DisplayName,
    ub.TotalBadges,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rp.CommentCount,
    CASE
        WHEN rp.PostRank = 1 THEN 'Latest'
        WHEN rp.PostRank <= 5 THEN 'Top 5'
        ELSE 'Other'
    END AS PostCategory
FROM 
    UserBadges ub
JOIN 
    Users u ON u.Id = ub.UserId
JOIN 
    (SELECT * FROM RankedPosts WHERE PostRank <= 10) rp ON u.Id = rp.OwnerUserId
WHERE 
    ub.TotalBadges IS NOT NULL 
ORDER BY 
    ub.TotalBadges DESC, 
    rp.ViewCount DESC
LIMIT 50;

-- To find users with no badges and their latest posts along with comment counts
UNION ALL 

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    0 AS TotalBadges,
    0 AS GoldBadges,
    0 AS SilverBadges,
    0 AS BronzeBadges,
    p.Id AS PostId,
    p.Title,
    p.ViewCount,
    p.Score,
    COUNT(c.Id) AS CommentCount,
    'No Badges' AS PostCategory
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    u.Id NOT IN (SELECT UserId FROM Badges)
GROUP BY 
    u.Id, p.Id
ORDER BY 
    u.DisplayName;
