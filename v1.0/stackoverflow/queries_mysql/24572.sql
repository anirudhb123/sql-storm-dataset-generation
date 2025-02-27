
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COALESCE(p.ClosedDate, '9999-12-31') AS ClosureDate 
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 30 DAY)
        AND p.ViewCount > 0
),
PostBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1 
    GROUP BY 
        b.UserId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        GROUP_CONCAT(DISTINCT pht.Name ORDER BY pht.Name SEPARATOR ', ') AS HistoryTypeNames,
        MAX(ph.CreationDate) AS LastHistoryDate
    FROM 
        PostHistory ph
    INNER JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.RankByScore,
    COALESCE(pb.BadgeCount, 0) AS GoldBadgeCount,
    phd.HistoryTypeNames,
    CASE 
        WHEN rp.ClosureDate < '2024-10-01 12:34:56' THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    CASE
        WHEN rp.CommentCount > 10 THEN 'Many Comments'
        WHEN rp.CommentCount IS NULL THEN 'No Comments'
        ELSE 'Few Comments'
    END AS CommentStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    PostBadges pb ON rp.PostId = pb.UserId
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
WHERE 
    rp.RankByScore <= 5 
ORDER BY 
    rp.CreationDate DESC;
