WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankByViews,
        COUNT(c.Id) AS CommentCount,
        AVG(v.BountyAmount) AS AvgBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.PostTypeId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS ClosureDate,
        ARRAY_AGG(DISTINCT cr.Name) AS CloseReasons,
        COUNT(ph.Id) AS HistoryCount
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON cr.Id::text = ph.Comment -- Assume comment contains CloseReasonId
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
    GROUP BY 
        ph.PostId, ph.CreationDate
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(p.ViewCount) AS TotalPostViews,
        MAX(p.CreationDate) AS LastActive
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
PostEngagement AS (
    SELECT 
        pp.PostId,
        pp.Title,
        pp.ViewCount,
        COALESCE(cp.ClosureDate, 'N/A') AS ClosureDate,
        COALESCE(cp.CloseReasons, ARRAY[]::varchar[]) AS CloseReasons,
        COALESCE(rp.RankByViews, 0) AS RankByViews,
        COALESCE(ua.BadgeCount, 0) AS UserBadgeCount,
        ua.TotalPostViews AS UserTotalPostViews
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
    LEFT JOIN 
        Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
    LEFT JOIN 
        UserActivity ua ON ua.UserId = u.Id
    WHERE 
        rp.RankByViews <= 10 -- Top 10 per PostType by View Count
)
SELECT 
    pe.PostId,
    pe.Title,
    pe.ViewCount,
    pe.ClosureDate,
    pe.CloseReasons,
    pe.RankByViews,
    pe.UserBadgeCount,
    pe.UserTotalPostViews,
    CASE 
        WHEN pe.ClosureDate IS NOT NULL 
        THEN 'Closed' 
        ELSE 'Open' 
    END AS PostStatus,
    CASE 
        WHEN pe.UserBadgeCount > 5 
        THEN 'Veteran' 
        ELSE 'Novice' 
    END AS UserType
FROM 
    PostEngagement pe
ORDER BY 
    pe.ViewCount DESC, pe.RankByViews, pe.UserBadgeCount DESC;
