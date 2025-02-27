WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.OwnerUserId,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RN,
        COALESCE(GREATEST(p.ViewCount, p.AnswerCount), 0) AS EngagementScore,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpvoteCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePostCount,
        COUNT(DISTINCT bh.Id) AS BadgeCount,
        AVG(p.ViewCount) AS AvgViewCount,
        STRING_AGG(DISTINCT pt.Name, ', ') AS PostTypes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges bh ON u.Id = bh.UserId
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        u.Id, u.DisplayName
),
LastClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        ph.UserId AS CloserUserId,
        ph.CreationDate AS CloseDate,
        (SELECT r.Name FROM PostHistoryTypes r WHERE r.Id = ph.PostHistoryTypeId) AS CloseAction,
        (SELECT c.Comment FROM Comments c WHERE c.PostId = p.Id ORDER BY c.CreationDate DESC LIMIT 1) AS LastComment
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
        AND ph.CreationDate >= NOW() - INTERVAL '1 month'
)
SELECT 
    rp.PostId,
    rpm.Title,
    rp.RN,
    ue.UserId,
    ue.DisplayName,
    ue.PositivePostCount,
    ue.BadgeCount,
    ue.AvgViewCount,
    rp.EngagementScore,
    lc.CloseDate,
    lc.LastComment
FROM 
    RankedPosts rp
LEFT JOIN 
    UserEngagement ue ON rp.OwnerUserId = ue.UserId
LEFT JOIN 
    LastClosedPosts lc ON rc.PostId = lc.PostId
WHERE 
    (rp.Score > 0 OR rp.RN < 6)  -- Include top posts or those with a score
    AND (lc.CloseDate IS NULL OR lc.CloseDate >= NOW() - INTERVAL '7 days')  -- Exclude recently closed posts
ORDER BY 
    rp.EngagementScore DESC, 
    ue.AvgViewCount DESC NULLS LAST;

### Explanation of SQL Constructs
1. **Common Table Expressions (CTEs)**: We use multiple CTEs (`RankedPosts`, `UserEngagement`, and `LastClosedPosts`) to segment our query into manageable parts, facilitating the collection of ranked posts, user engagement data, and recently closed posts.

2. **Window Functions**: The query uses the `ROW_NUMBER()` window function to rank posts based on their `CreationDate`, partitioned by `PostTypeId`, which allows us to isolate the most recent posts per type.

3. **Correlated Subqueries**: Inside `RankedPosts` and `UserEngagement`, correlated subqueries are used to count related rows in the `Votes` and `Badges` tables, respectively.

4. **Outer Joins**: `LEFT JOIN` ensures we keep all posts and users regardless of their relationships, particularly to capture users with no posts or badges.

5. **Null Logic**: The final `WHERE` clause incorporates NULL logic to filter out recently closed posts while allowing posts that are either positively scored or in the top ranks.

6. **Complicated Predicates**: The `WHERE` clause employs compound conditions, integrating both positivity in scores and ranking logic, while excluding certain post states.

7. **String Expressions**: The use of `STRING_AGG()` collects post type names into a single string for user engagement results.

This query provides a complex view combining various facets of posts and users, respecting the intricacies of the data schema while showing advanced SQL techniques for performance benchmarking.
