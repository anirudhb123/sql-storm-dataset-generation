WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days' AND
        p.Score IS NOT NULL
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges,
        MAX(b.Class) AS HighestBadgeClass,
        MIN(b.Date) AS FirstBadgeDate
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
RecentComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    WHERE 
        c.CreationDate >= CURRENT_DATE - INTERVAL '60 days'
    GROUP BY 
        c.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(ph.PostId) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        COALESCE(rc.CommentCount, 0) AS RecentComments,
        COALESCE(cp.CloseCount, 0) AS CloseCount,
        ub.TotalBadges / NULLIF(ub.TotalBadges, 0) AS BadgeProportion
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentComments rc ON rp.PostId = rc.PostId
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
    LEFT JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    WHERE 
        rp.PostRank <= 5
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.RecentComments,
    ps.CloseCount,
    CASE 
        WHEN ps.CloseCount > 0 AND ps.BadgeProportion IS NOT NULL THEN 'Potential Quality Concerns'
        WHEN ps.CloseCount = 0 AND ps.BadgeProportion IS NULL THEN 'No Badges'
        ELSE 'Normal'
    END AS QualityStatus
FROM 
    PostStatistics ps
WHERE 
    ps.ViewCount > 100
ORDER BY 
    ps.Score DESC, ps.RecentComments DESC;
