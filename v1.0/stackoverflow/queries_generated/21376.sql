WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankByViews,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpvoteCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS WasClosed,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.RankByViews,
        COALESCE(phs.WasClosed, 0) AS IsClosed,
        phs.CloseReopenCount,
        ub.BadgeCount,
        ub.BadgeNames
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryStats phs ON rp.PostId = phs.PostId
    LEFT JOIN 
        UserBadges ub ON rp.RankByViews = 1  -- Get the top post per user for badges
)
SELECT 
    *,
    CASE 
        WHEN IsClosed = 1 THEN 'Closed'
        WHEN CloseReopenCount > 0 THEN 'Moved between Closed and Open'
        ELSE 'Open'
    END AS PostStatus,
    CASE 
        WHEN BadgeCount IS NULL THEN 'No Badges'
        ELSE BadgeNames
    END AS UserBadgesSummary
FROM 
    FinalResults
WHERE 
    (BadgeCount > 0 OR RankByViews <= 3)
ORDER BY 
    ViewCount DESC, CreationDate ASC
OFFSET 0 ROWS
FETCH NEXT 100 ROWS ONLY;

This query accomplishes several advanced SQL tasks:

- It utilizes Common Table Expressions (CTEs) for better readability and organization of the query.
- It performs outer joins to gather related data.
- It uses window functions (ROW_NUMBER) to rank posts based on view counts.
- It incorporates aggregation and conditional logic to summarize the states of posts and users, embedding nuanced checks for closures and badge counts.
- The query includes complex predicates within `CASE` statements and retrieves user badges concisely with `STRING_AGG`.
- The main query leverages filtering conditions to refine output, with a result set limited to 100 rows for performance testing.
