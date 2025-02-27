
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName, p.PostTypeId
),
RecentBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Date >= DATEADD(year, -1, '2024-10-01 12:34:56')
    GROUP BY 
        b.UserId
),
PostHistoryAggregates AS (
    SELECT 
        h.PostId,
        STRING_AGG(DISTINCT h.UserDisplayName, ', ') AS Editors,
        COUNT(CASE WHEN h.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN h.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount
    FROM 
        PostHistory h
    GROUP BY 
        h.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    rp.RankScore,
    COALESCE(rb.BadgeCount, 0) AS RecentBadgesCount,
    COALESCE(rb.BadgeNames, 'None') AS RecentBadgeNames,
    pha.Editors,
    pha.CloseCount,
    pha.ReopenCount
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentBadges rb ON rp.OwnerDisplayName = CAST(rb.UserId AS VARCHAR)
LEFT JOIN 
    PostHistoryAggregates pha ON rp.PostId = pha.PostId
WHERE 
    rp.RankScore <= 5 
    AND rp.ViewCount > 100 
    AND (rp.Score IS NOT NULL OR rp.ViewCount IS NOT NULL) 
ORDER BY 
    rp.Score DESC,
    rp.ViewCount DESC,
    rp.CreationDate DESC;
