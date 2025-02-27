WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    WHERE
        p.Score > 0 AND
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY
        p.Id, p.OwnerUserId, p.CreationDate, p.Score, p.Tags
),
TopUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS ActivePostCount,
        SUM(COALESCE(bp.Class, 0)) AS TotalBadgeClass
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Badges bp ON u.Id = bp.UserId
    WHERE
        u.Reputation >= 100 AND
        u.CreationDate < CURRENT_DATE - INTERVAL '1 year'
    GROUP BY
        u.Id, u.DisplayName, u.Reputation
    HAVING
        COUNT(DISTINCT p.Id) > 2
),
PostHistorySummary AS (
    SELECT
        ph.PostId,
        MIN(ph.CreationDate) AS FirstEdit,
        MAX(ph.CreationDate) AS LastEdit,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM
        PostHistory ph
    JOIN
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY
        ph.PostId
)
SELECT
    ru.UserId,
    ru.DisplayName,
    ru.Reputation,
    ru.ActivePostCount,
    ru.TotalBadgeClass,
    rp.Rank,
    rp.PostId,
    rp.Score,
    phs.FirstEdit,
    phs.LastEdit,
    COALESCE(phs.HistoryTypes, 'No edits') AS EditHistory
FROM
    TopUsers ru
LEFT JOIN
    RankedPosts rp ON ru.UserId = rp.OwnerUserId AND rp.Rank = 1
LEFT JOIN
    PostHistorySummary phs ON rp.PostId = phs.PostId
WHERE
    COALESCE(rp.Score, 0) > 10
ORDER BY
    ru.TotalBadgeClass DESC,
    ru.ActivePostCount DESC,
    phs.FirstEdit DESC
LIMIT 50;

### Explanation:
1. **Common Table Expressions (CTEs)**:
   - `RankedPosts`: Ranks posts by score for each user who authored them, only considering posts created in the last year that have a score greater than 0, and aggregates the comment count.
   - `TopUsers`: Identifies users with reputation over 100 who have been active for over a year, counting their distinct posts and summing their badge classes.
   - `PostHistorySummary`: Summarizes the history of edits for the posts, capturing the first and last edit dates along with the types of history events.

2. **Main Query**:
   - Joins the summary of top users with their highest-ranked posts and the edit history of those posts.
   - Filters posts for those with a score greater than 10.
   - Orders the final output by total badge class, number of active posts, and the first edit date.

3. **Output**:
   - The resulting dataset includes users with noteworthy contributions, their best posts, and details about the editing history of those posts—providing an elaborate view of user engagement and post history within the schema's context. 

4. **NULL Logic**:
   - The `COALESCE` function is used to handle nulls in multiple areas (e.g., setting default values for edit histories).
  
This complex query showcases the schema’s various facets and SQL features for a robust analytical report.
