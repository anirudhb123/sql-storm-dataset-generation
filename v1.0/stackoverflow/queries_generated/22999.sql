WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COUNT(v.Id) OVER (PARTITION BY p.Id, v.VoteTypeId) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 -- considering only UpVotes
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.Score IS NOT NULL
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        pt.Name AS PostHistoryType,
        CASE 
            WHEN pt.Name = 'Post Closed' AND ph.Comment IS NOT NULL THEN ph.Comment
            ELSE 'No reason provided'
        END AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        pt.Name IN ('Post Closed', 'Post Reopened')
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        (SELECT COUNT(*) FROM Badges b WHERE b.UserId = u.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    ra.PostId,
    ra.Title,
    ra.CreationDate,
    ra.ViewCount,
    ra.Score,
    ra.CommentCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    IFNULL(cp.CloseReason, 'Active') AS PostStatus,
    ua.PostsCreated,
    ua.TotalViews,
    ua.BadgeCount,
    CASE 
        WHEN ra.PostRank = 1 THEN 'Top Post'
        WHEN ra.PostRank <= 5 THEN 'Top 5 Posts'
        ELSE 'Other Posts'
    END AS PostCategory
FROM 
    RankedPosts ra
JOIN 
    Users u ON ra.OwnerUserId = u.Id
LEFT JOIN 
    ClosedPosts cp ON ra.PostId = cp.PostId
LEFT JOIN 
    UserActivity ua ON u.Id = ua.UserId
WHERE 
    ra.CommentCount > 0 OR ra.ViewCount > 100
ORDER BY 
    ra.Score DESC, ra.ViewCount DESC
LIMIT 100;

This SQL query includes multiple constructs such as:

1. **Common Table Expressions (CTEs)**: 
   - `RankedPosts` ranks posts based on their scores and calculates the number of comments and upvotes.
   - `ClosedPosts` retrieves closed posts along with their closure reason.
   - `UserActivity` aggregates user activity statistics including total views and badge counts.

2. **Window Functions**: 
   - Used to rank posts per user and count votes.

3. **LEFT JOINs**: 
   - To incorporate comments and vote details, allowing for posts that might not have any comments or votes.

4. **CORRELATED Subquery**: 
   - Inside the `UserActivity` CTE, to count the number of badges for each user.

5. **ELSE Conditions**: 
   - Conditional logic to manage `NULL` values and provide default values.

6. **Complex Filtering**: 
   - Comments or views provided specific conditions maintain meaningfulness in post selection.

7. **CASE Statements**: 
   - To categorize posts based on rank and display meaningful labels.

The entire query is designed for performance benchmarking, focusing on a rich dataset derived from various interconnected tables while also managing edge cases and NULL logic effectively.
