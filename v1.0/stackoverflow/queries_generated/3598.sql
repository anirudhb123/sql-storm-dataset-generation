WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 AND  -- Only questions
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
AggregatedUserData AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COALESCE(MAX(p.ViewCount), 0) AS MaxViews,
        COALESCE(SUM(p.Score), 0) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
)
SELECT 
    r.OwnerUserId,
    u.DisplayName,
    r.Title,
    r.Score,
    r.ViewCount,
    au.GoldBadges,
    au.SilverBadges,
    au.BronzeBadges,
    au.MaxViews,
    au.TotalScore,
    r.CommentCount
FROM 
    RankedPosts r
JOIN 
    Users u ON r.OwnerUserId = u.Id
JOIN 
    AggregatedUserData au ON u.Id = au.UserId
WHERE 
    r.Rank <= 3  -- Top 3 questions per user
ORDER BY 
    au.TotalScore DESC, r.Score DESC
LIMIT 100;
