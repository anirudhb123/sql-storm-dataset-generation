WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
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
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount
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
        rp.ViewCount,
        rp.CreationDate,
        ub.BadgeCount,
        ub.HighestBadgeClass,
        cp.CloseCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    LEFT JOIN 
        ClosedPostHistory cp ON rp.PostId = cp.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.CreationDate,
    COALESCE(ps.BadgeCount, 0) AS BadgeCount,
    ps.HighestBadgeClass,
    COALESCE(ps.CloseCount, 0) AS CloseCount,
    DATEDIFF(CURRENT_TIMESTAMP, ps.CreationDate) AS AgeInDays,
    CASE 
        WHEN ps.CloseCount > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    PostStatistics ps
WHERE 
    ps.Rank <= 3 -- Fetch top 3 questions per user
ORDER BY 
    ps.ViewCount DESC, ps.CreationDate DESC;
