WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(month, -6, GETDATE())
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
PostsWithBadges AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        ub.BadgeCount,
        ub.HighestBadgeClass
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
)
SELECT 
    p.Title,
    p.CreationDate,
    p.Score,
    p.CommentCount,
    COALESCE(p.BadgeCount, 0) AS BadgeCount,
    CASE 
        WHEN p.HighestBadgeClass = 1 THEN 'Gold'
        WHEN p.HighestBadgeClass = 2 THEN 'Silver'
        WHEN p.HighestBadgeClass = 3 THEN 'Bronze'
        ELSE 'None'
    END AS HighestBadge
FROM 
    PostsWithBadges p
WHERE 
    p.rn = 1
ORDER BY 
    p.Score DESC, p.CreationDate DESC
LIMIT 100;
