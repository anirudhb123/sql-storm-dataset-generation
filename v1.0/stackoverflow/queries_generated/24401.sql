WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR' 
        AND p.Score > 0
        AND p.PostTypeId = 1 -- Only Questions
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    COALESCE(ub.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(phd.CloseCount, 0) AS CloseCount,
    COALESCE(phd.ReopenCount, 0) AS ReopenCount,
    ARRAY_AGG(DISTINCT tg.TagName) AS Tags,
    CASE 
        WHEN phd.LastClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
LEFT JOIN 
    UNNEST(string_to_array(rp.Tags, ',')) AS tag ON TRUE 
LEFT JOIN 
    Tags tg ON LOWER(tg.TagName) = LOWER(tag)
WHERE 
    rp.rn = 1 -- Latest post per user
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, ub.BadgeCount, phd.CloseCount, phd.ReopenCount
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 100;
