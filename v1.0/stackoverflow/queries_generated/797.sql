WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) as Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND p.Score IS NOT NULL
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
),
TopRankedPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        ub.BadgeCount,
        ub.HighestBadgeClass
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    WHERE 
        rp.Rank <= 5
)
SELECT 
    trp.Title,
    trp.CreationDate,
    trp.Score,
    trp.ViewCount,
    COALESCE(NULLIF(trp.BadgeCount, 0), 'No Badges') AS BadgeCount,
    CASE 
        WHEN trp.HighestBadgeClass = 1 THEN 'Gold'
        WHEN trp.HighestBadgeClass = 2 THEN 'Silver'
        WHEN trp.HighestBadgeClass = 3 THEN 'Bronze'
        ELSE 'No Badge'
    END AS HighestBadge
FROM 
    TopRankedPosts trp
WHERE 
    trp.Score > (SELECT AVG(Score) FROM Posts WHERE PostTypeId = 1) 
ORDER BY 
    trp.Score DESC
LIMIT 10;
