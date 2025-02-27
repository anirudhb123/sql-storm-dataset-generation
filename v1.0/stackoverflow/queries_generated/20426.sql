WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(sub_query.CommentCount, 0)) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT 
            PostId,
            COUNT(*) AS CommentCount
         FROM 
            Comments 
         GROUP BY 
            PostId) sub_query ON p.Id = sub_query.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
UserRanked AS (
    SELECT 
        ua.*,
        RANK() OVER (ORDER BY ua.Upvotes DESC, ua.TotalViews DESC, ua.PostCount DESC) AS UserRank
    FROM 
        UserActivity ua
),
ClosedPosts AS (
    SELECT 
        p.Id,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS LatestHistory
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  -- Post Closed or Reopened
)
SELECT 
    ur.UserId,
    ur.DisplayName,
    ur.PostCount,
    ur.Upvotes,
    ur.Downvotes,
    ur.TotalViews,
    ur.TotalComments,
    ur.UserRank,
    COUNT(DISTINCT cp.Id) AS ClosedPostCount,
    AVG(CASE WHEN cp.LatestHistory = 1 THEN 1 ELSE 0 END) AS ReopenedPosts
FROM 
    UserRanked ur
LEFT JOIN 
    ClosedPosts cp ON ur.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = cp.Id)
GROUP BY 
    ur.UserId, ur.DisplayName, ur.PostCount, ur.Upvotes, ur.Downvotes, ur.TotalViews, ur.TotalComments, ur.UserRank
HAVING 
    ur.UserRank <= 10 OR (COUNT(DISTINCT cp.Id) > 0 AND ur.TotalViews > 100)
ORDER BY 
    ur.UserRank;

This SQL query incorporates several advanced SQL concepts as requested:

1. **CTEs**: The query uses multiple Common Table Expressions (CTEs) to break down the logic into manageable parts: `UserActivity`, `UserRanked`, and `ClosedPosts`.
  
2. **Window Functions**: 
   - The `RANK()` function in `UserRanked` ranks users based on their upvotes, total views, and post count.
   - `ROW_NUMBER()` in the `ClosedPosts` CTE orders the post history to determine the latest actions on closed posts.

3. **Join Logic**: Includes left joins on various entities to gather comprehensive data while maintaining the user context.

4. **Aggregation**: The query aggregates data on user activity—counts and sums—including distinct counts of closed posts and averages for reopened posts.

5. **NULL Logic & COALESCE**: Resilient against NULLs, it safely sums views, comments, and posts with COALESCE.

6. **HAVING Clause**: Filters results based on rank or specific conditions—users who are either in the top 10 or have closed posts counted above a threshold with significant views.

7. **Complex Predicate Logic**: The having clause incorporates logical checks for user ranking and closed post counts.

The overall complexity of the query is confident in demonstrating SQL capabilities while tackling multiple data points relevant to a comprehensive user activity overview.
