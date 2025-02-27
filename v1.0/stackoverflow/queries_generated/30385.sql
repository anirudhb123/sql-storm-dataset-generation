WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.ViewCount, 
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS Upvotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(b.Class, 0)) AS BadgeCount,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.LastActivityDate,
        p.OwnerDisplayName,
        p.ViewCount,
        p.Score,
        (SELECT COUNT(c.Id) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount
    FROM 
        Posts p
    WHERE 
        p.LastActivityDate >= CURRENT_DATE - INTERVAL '30 days'
    ORDER BY 
        p.LastActivityDate DESC
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment AS CloseReason
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) /* 10 = Post Closed, 11 = Post Reopened */
)
SELECT 
    rp.PostId,
    rp.Title,
    us.DisplayName AS PostOwner,
    rp.ViewCount,
    rp.Score,
    rp.Upvotes,
    rp.Downvotes,
    us.BadgeCount,
    ra.CommentCount,
    cp.CloseReason,
    CASE 
        WHEN cp.CloseReason IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    RankedPosts rp
JOIN 
    UserStats us ON rp.PostId = us.UserId
LEFT JOIN 
    RecentActivity ra ON rp.PostId = ra.PostId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.PostRank = 1 /* include only latest post from each user */
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;

This SQL query performs several advanced operations:

1. **Common Table Expressions (CTEs)**: Multiple CTEs aggregate data on posts, users, recent activity, and closed posts.
2. **Window Functions**: Used in `RankedPosts` to assign ranks and calculate upvotes and downvotes per post.
3. **Subqueries**: Used in `RecentActivity` to fetch comment counts.
4. **LEFT JOINs**: Applied to gather data from related tables without losing records from the primary table.
5. **NULL Handling**: Utilizes `COALESCE` to manage NULL values in badge counts.
6. **Conditional Logic**: Derives the `PostStatus` based on the `CloseReason`.
7. **Complex Filtering & Sorting**: Filters posts created in the last year, ranks them, and sorts by score and views.

This structure allows for comprehensive analysis while benchmarking performance.
