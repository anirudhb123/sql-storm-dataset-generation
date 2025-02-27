WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountySpent
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostHistoryAggregated AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount,
        COUNT(*) AS TotalHistoryEntries
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    us.DisplayName AS TopUser,
    us.BadgeCount,
    us.TotalBountySpent,
    COALESCE(ph.CloseCount, 0) AS CloseCount,
    COALESCE(ph.ReopenCount, 0) AS ReopenCount,
    COALESCE(ph.TotalHistoryEntries, 0) AS TotalHistoryEntries
FROM 
    RankedPosts rp
LEFT JOIN 
    UserStatistics us ON rp.PostId = (
        SELECT 
            p.OwnerUserId 
        FROM 
            Posts p 
        WHERE 
            p.Id = rp.PostId
    )
LEFT JOIN 
    PostHistoryAggregated ph ON rp.PostId = ph.PostId
WHERE 
    rp.ScoreRank <= 10
    AND us.BadgeCount > 0
ORDER BY 
    rp.Score DESC, 
    us.BadgeCount DESC
UNION ALL
SELECT 
    -1 AS PostId,
    'No Active Posts' AS Title,
    NULL AS Score,
    'N/A' AS TopUser,
    0 AS BadgeCount,
    0 AS TotalBountySpent,
    0 AS CloseCount,
    0 AS ReopenCount,
    0 AS TotalHistoryEntries
WHERE 
    NOT EXISTS (SELECT 1 FROM Posts)
LIMIT 50;
