WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.ViewCount IS NOT NULL
),
RecentActivity AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT pht.Name, ', ') AS LastEditTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '6 months'
    GROUP BY 
        ph.PostId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        SUM(COALESCE(b.Class, 0)) AS BadgePoints,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
)
SELECT 
    p.Title,
    p.CreationDate,
    u.DisplayName,
    u.Reputation,
    COALESCE(rp.PostRank, -1) AS PostRank,
    ra.LastEditDate,
    ra.LastEditTypes,
    COALESCE(us.VoteCount, 0) AS UserVoteCount,
    us.BadgePoints,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount
FROM 
    Posts p
LEFT JOIN 
    RankedPosts rp ON p.Id = rp.PostId
LEFT JOIN 
    RecentActivity ra ON p.Id = ra.PostId
LEFT JOIN 
    UserStats us ON p.OwnerUserId = us.UserId
WHERE 
    p.PostTypeId = 1  -- Questions only
    AND (p.Score > 0 OR p.ViewCount > 50)
ORDER BY 
    p.CreationDate DESC
LIMIT 100;

This SQL query provides a performance benchmarking case by:

1. **Common Table Expressions (CTEs)**: It uses three CTEs to rank posts by their creation date, summarize recent activity, and calculate user statistics.

2. **Window Functions**: It applies a `ROW_NUMBER()` window function to rank posts for each user based on their creation date.

3. **Outer Joins**: It employs LEFT JOINs to gather data from related tables, ensuring all relevant information about posts, users, and badges is included even if some of them do not have related records.

4. **String Aggregation**: Utilizes `STRING_AGG` to concatenate edit types for the posts in a readable format.

5. **NULL Logic and COALESCE**: Handles potential NULL values gracefully using `COALESCE`.

6. **Subqueries**: Incorporates a subquery to count comments related to each post, which provides additional metrics.

7. **Predicates and Filtering**: Applies complex filtering criteria to ensure only relevant posts are evaluated.

8. **Ordering and Limiting**: Sorts the results by the creation date and limits the output to the most recent 100 posts, making it efficient for performance assessment.

The query effectively balances complexity and clarity while demonstrating the capabilities of SQL features for performance analysis.
