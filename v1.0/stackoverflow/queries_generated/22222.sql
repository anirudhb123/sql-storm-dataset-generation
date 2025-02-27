WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RecentRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, p.PostTypeId
), UserReputation AS (
    SELECT 
        u.Id AS UserId,
        SUM(b.Class) AS TotalBadges,
        AVG(u.Reputation) AS AvgReputation
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
), ClosureReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS ClosureReasons
    FROM PostHistory ph
    JOIN CloseReasonTypes cr ON ph.Comment = CAST(cr.Id AS VARCHAR)
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.CommentCount,
    CASE 
        WHEN ur.TotalBadges IS NULL THEN 0 
        ELSE ur.TotalBadges 
    END AS UserTotalBadges,
    COALESCE(ur.AvgReputation, 0) AS UserAvgReputation,
    COALESCE(cr.ClosureReasons, 'Not Closed') AS ClosureReasons
FROM RankedPosts rp
LEFT JOIN UserReputation ur ON rp.PostId = ur.UserId
LEFT JOIN ClosureReasons cr ON rp.PostId = cr.PostId
WHERE rp.RecentRank <= 5 
AND (ur.AvgReputation IS NULL OR ur.AvgReputation > 100) 
OR (cr.ClosureReasons IS NOT NULL AND ur.TotalBadges >= 1)
ORDER BY rp.CommentCount DESC, rp.CreationDate DESC
LIMIT 10;

### Explanation:

1. **CTEs Used**:
   - `RankedPosts`: Gathers posts created in the last year, counting comments, and ranking them by creation date within their post type.
   - `UserReputation`: Computes the total badges and average reputation of users.
   - `ClosureReasons`: Aggregates closure reasons for posts that have been closed.

2. **Main Query**: Joins the ranked posts with user reputation and closure reasons:
   - Retrieving the top 5 most recent posts by type along with relevant user metrics.
   - It uses `COALESCE` and `CASE` to handle NULL values in badge counts and closure reasons and applies predicates to filter based on user metrics.

3. **Filtering Logic**: The `WHERE` clause combines:
   - Selection for recent posts.
   - Reputation criteria.
   - Closure conditions.

4. **ORDER BY and LIMIT**: It sorts results by comment count and post creation date to prioritize engagement and caps the result set to 10 entries.

This query harnesses complex SQL features, exhibits extensive use of different constructs, and showcases corner cases for NULL handling and ranking.
