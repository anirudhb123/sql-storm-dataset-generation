WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS Owner,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.ViewCount IS NOT NULL
),
FilteredBadges AS (
    SELECT 
        b.UserId,
        COUNT(B.Id) AS BadgeCount,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Badges b
    WHERE 
        b.Class = 1 
    GROUP BY 
        b.UserId
),
PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryEntries,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
),
PostsWithBadgeCounts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CreationDate,
        rp.Owner,
        COALESCE(fb.BadgeCount, 0) AS BadgeCount,
        COALESCE(phg.HistoryEntries, 0) AS HistoryEntries,
        phg.HistoryTypes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        FilteredBadges fb ON rp.Owner = fb.UserId
    LEFT JOIN 
        PostHistoryAggregates phg ON rp.PostId = phg.PostId
)
SELECT 
    pwbc.PostId,
    pwbc.Title,
    pwbc.ViewCount,
    pwbc.Owner,
    pwbc.BadgeCount,
    pwbc.HistoryEntries,
    pwbc.HistoryTypes,
    CASE 
        WHEN pwbc.BadgeCount > 2 THEN 'Expert'
        WHEN pwbc.BadgeCount BETWEEN 1 AND 2 THEN 'Novice'
        ELSE 'Unbadge'
    END AS UserCategory,
    (SELECT COUNT(*) 
     FROM Comments c 
     WHERE c.PostId = pwbc.PostId) AS CommentCount,
    COALESCE(
        (SELECT MAX(ClosedDate) 
         FROM Posts p 
         WHERE p.Id = pwbc.PostId AND p.ClosedDate IS NOT NULL),
        'Not Closed') AS LastClosedDate
FROM 
    PostsWithBadgeCounts pwbc
WHERE 
    pwbc.Rank <= 5
ORDER BY 
    pwbc.ViewCount DESC;
