WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.PostTypeId = 1  -- Only Questions
),
PostBadges AS (
    SELECT 
        ub.UserId,
        b.Name AS BadgeName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    JOIN 
        Users ub ON b.UserId = ub.Id
    GROUP BY 
        ub.UserId, b.Name
),
TopBadges AS (
    SELECT 
        UserId,
        BadgeName,
        BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY UserId ORDER BY BadgeCount DESC) AS BadgeRank
    FROM 
        PostBadges
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    tb.BadgeName,
    tb.BadgeCount
FROM 
    RankedPosts rp
LEFT JOIN 
    TopBadges tb ON rp.OwnerUserId = tb.UserId AND tb.BadgeRank = 1
WHERE 
    rp.Rank <= 5  -- Top 5 posts per user
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 100;
