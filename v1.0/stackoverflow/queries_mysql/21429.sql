
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATE_SUB(CAST('2024-10-01' AS DATE), INTERVAL 1 YEAR)
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        GROUP_CONCAT(DISTINCT cr.Name ORDER BY cr.Name SEPARATOR ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment = CAST(cr.Id AS CHAR)
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        COALESCE(cp.CloseCount, 0) AS CloseCount,
        COALESCE(cp.CloseReasons, 'None') AS CloseReasons,
        rp.Reputation,
        CASE 
            WHEN rp.Rank <= 5 THEN 'Top Performer'
            ELSE 'Regular Performer'
        END AS PerformanceCategory
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.CloseCount,
    ps.CloseReasons,
    ps.Reputation,
    ps.PerformanceCategory,
    CASE 
        WHEN ps.CloseCount > 0 THEN 'Engagement with Risk'
        ELSE 'Stable Engagement'
    END AS EngagementRisk,
    (SELECT COUNT(*) 
     FROM Comments c 
     WHERE c.PostId = ps.PostId) AS CommentCount
FROM 
    PostStatistics ps
WHERE 
    ps.Reputation > 100 
ORDER BY 
    ps.Score DESC, ps.CloseCount ASC;
