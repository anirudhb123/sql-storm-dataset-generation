WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Questions only
        AND p.Score > 0
), 

UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
), 

PostHistoryStats AS (
    SELECT 
        h.UserId,
        COUNT(*) AS EditsMade,
        AVG(DATEDIFF(MINUTE, h.CreationDate, GETDATE())) AS AvgEditTimeInMinutes
    FROM 
        PostHistory h
    WHERE 
        h.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
    GROUP BY 
        h.UserId
)

SELECT 
    rp.Id AS PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate,
    rp.OwnerUserId,
    rp.OwnerDisplayName,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    phs.EditsMade,
    phs.AvgEditTimeInMinutes
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
LEFT JOIN 
    PostHistoryStats phs ON rp.OwnerUserId = phs.UserId
WHERE 
    rp.Rank = 1 -- Only top-scoring question per user
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 100; -- Limit to top 100 results
