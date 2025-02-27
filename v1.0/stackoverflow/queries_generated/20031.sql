WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank,
        COALESCE(NULLIF(p.LastActivityDate, p.CreationDate), p.LastEditDate) AS LastActive
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.Score >= 0
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, u.DisplayName, p.LastActivityDate, p.LastEditDate
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.PostRank,
        CASE 
            WHEN rp.CommentCount > 0 THEN 'Active'
            ELSE 'Inactive'
        END AS ActivityStatus
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5 -- Top 5 posts per type
),
PostStatistics AS (
    SELECT 
        f.OwnerDisplayName,
        COUNT(f.PostId) AS PostsCount,
        SUM(f.Score) AS TotalScore,
        AVG(f.Score) AS AvgScore,
        MAX(f.CreationDate) AS LatestPostDate,
        STRING_AGG(DISTINCT CASE WHEN f.ActivityStatus = 'Active' THEN f.Title END, ', ') AS ActivePosts
    FROM 
        FilteredPosts f
    GROUP BY 
        f.OwnerDisplayName
)
SELECT 
    ps.OwnerDisplayName,
    ps.PostsCount,
    ps.TotalScore,
    ps.AvgScore,
    ps.LatestPostDate,
    CASE 
        WHEN ps.PostsCount IS NULL THEN 'No Posts'
        WHEN ps.AvgScore > 20 THEN 'Highly Engaged'
        ELSE 'Moderately Engaged'
    END AS EngagementLevel,
    COALESCE(ps.ActivePosts, 'No Active Posts') AS ActivePostsList
FROM 
    PostStatistics ps
ORDER BY 
    ps.TotalScore DESC;

### Explanation:
1. **Common Table Expressions (CTEs)**:
   - `RankedPosts`: This CTE calculates the rank of each post based on the score and collects comments.
   - `FilteredPosts`: This filters the top 5 posts per type and assesses their activity status.
   - `PostStatistics`: This collects aggregated statistics about posts per user.

2. **Projection and Logic**:
   - The final selection aggregates the statistics, calculating total posts, average score, and the latest post date per user.
   - The case statements are used for engagement levels and active post listing, demonstrating both NULL handling and conditional logic.

3. **Window Function**:
   - `ROW_NUMBER()`: Used to rank posts by score within their types.

4. **String Aggregation**:
   - `STRING_AGG`: To create a comma-separated list of active posts.

5. **NULL Logic**:
   - `COALESCE` and `CASE`: Used to handle potential NULL values gracefully, especially in calculating 'ActivePostsList'.

This query pushes database features such as CTEs, window functions, aggregation, conditional logic, and NULL handling to their limits, ensuring a comprehensive performance benchmark.
