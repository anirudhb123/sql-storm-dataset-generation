WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankByViewCount,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstCloseDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rp.RankByViewCount,
    rp.CommentCount,
    COALESCE(cp.FirstCloseDate, 'No closures') AS ClosureDate,
    ub.UserId AS BadgeHolder,
    ub.TotalBadges,
    ub.GoldBadges,
    CASE 
        WHEN rp.ViewCount = 0 THEN 'No Views'
        WHEN rp.ViewCount < 100 THEN 'Low Activity'
        WHEN rp.ViewCount BETWEEN 100 AND 500 THEN 'Moderate Activity'
        ELSE 'High Activity'
    END AS ActivityLevel
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN 
    UserBadges ub ON rp.ViewCount > 1000
WHERE 
    rp.RankByViewCount <= 5
    AND rp.CommentCount > 0
ORDER BY 
    rp.ViewCount DESC, rp.Score DESC;

This SQL query incorporates several advanced SQL constructs:

1. **Common Table Expressions (CTEs)**: `RankedPosts`, `ClosedPosts`, and `UserBadges` are used to simplify the main query. Each CTE accumulates data in a logical way and computes necessary aggregates.
  
2. **Window Functions**:
   - `ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC)` ranks posts based on their view count within their post type.
   - `COUNT(c.Id) OVER (PARTITION BY p.Id)` counts comments for each post.

3. **Outer Joins**: The query uses multiple left joins to further extract details from related tables, allowing for complete data aggregation when some relationships may not exist.

4. **COALESCE Function**: It replaces NULL values from closed posts with the string 'No closures'.

5. **Complicated Case Expressions**: It classifies posts based on their view counts into activity levels.

6. **Complex Predicates and Filtering**: The main query applies various filters and conditions to hone in on specific data characteristics, like activity levels and ranks.

This query showcases performance-intensive analytics by combining metrics and user engagement while drawing variables from multiple related tables and ensuring robustness via NULL handling.
