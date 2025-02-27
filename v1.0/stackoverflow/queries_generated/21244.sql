WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.CreationDate,
        p.Title,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1 -- Only questions
),
ClosedPosts AS (
    SELECT
        ph.PostId,
        ph.CreationDate AS ClosedDate,
        ph.Comment AS CloseReason
    FROM
        PostHistory ph
    WHERE
        ph.PostHistoryTypeId = 10 -- Post Closed
),
PostsWithBadges AS (
    SELECT
        u.Id AS UserId,
        MAX(b.Class) AS HighestBadgeClass,
        COUNT(b.Id) AS BadgeCount
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id
),
UserStats AS (
    SELECT
        u.Id,
        u.DisplayName,
        COALESCE(b.BadgeCount, 0) AS BadgeCount,
        COALESCE(rb.HighestBadgeClass, 0) AS HighestBadgeClass,
        COALESCE(cp.ClosedCount, 0) AS ClosedCount
    FROM
        Users u
    LEFT JOIN
        PostsWithBadges b ON u.Id = b.UserId
    LEFT JOIN (
        SELECT
            p.OwnerUserId,
            COUNT(*) AS ClosedCount
        FROM
            ClosedPosts cp
        JOIN
            Posts p ON cp.PostId = p.Id
        GROUP BY
            p.OwnerUserId
    ) cp ON u.Id = cp.OwnerUserId
)
SELECT
    us.DisplayName,
    us.BadgeCount,
    us.HighestBadgeClass,
    us.ClosedCount,
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount
FROM
    UserStats us
JOIN
    RankedPosts rp ON us.Id = rp.OwnerUserId
WHERE
    us.ClosedCount > 0
    AND rp.rn <= 5 -- Getting the top 5 most recent questions per user
ORDER BY
    us.BadgeCount DESC, 
    rp.Score DESC,
    rp.ViewCount DESC;

### Explanation:

1. **CTEs:**
   - **RankedPosts:** Ranks questions per user by their creation date.
   - **ClosedPosts:** Retrieves closed posts and their close reasons.
   - **PostsWithBadges:** Aggregates users with their highest badge class and badge count.
   - **UserStats:** Combines user info with badge details and closed post counts.

2. **Main Query:**
   - Joins user statistics with ranked posts.
   - Filters users with closed posts and limits results to their most recent questions.

3. **Conditions and Ordering:**
   - Filters results to users with at least one closed post, and limits results to the top 5 recent questions.
   - Orders results by badge count, score, and view count to highlight high-performing users. 

4. **NULL Logic:** 
   - Utilizes `COALESCE` to handle potential NULL values for badge counts and closed count.

5. **Bizarre Semantics:**
   - Combines detailed statistics and filtering criteria in one structured query reflecting various user engagement metrics, including badge recognition and post visibility through user activities.
