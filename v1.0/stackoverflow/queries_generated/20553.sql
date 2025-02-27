WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
), 
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        COALESCE(u.Reputation, 0) AS OwnerReputation,
        rp.CommentCount,
        CASE 
            WHEN rp.Score >= 100 THEN 'High Score'
            WHEN rp.Score >= 50 THEN 'Medium Score'
            ELSE 'Low Score'
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.ScoreRank = 1
), 
AggregateData AS (
    SELECT
        ScoreCategory,
        COUNT(*) AS PostCount,
        AVG(OwnerReputation) AS AvgReputation,
        MAX(ViewCount) AS MaxViewCount,
        MIN(CASE WHEN CommentCount IS NULL THEN 0 ELSE CommentCount END) AS MinCommentCount
    FROM 
        PostStats
    GROUP BY 
        ScoreCategory
)
SELECT 
    ad.ScoreCategory,
    ad.PostCount,
    ad.AvgReputation,
    ad.MaxViewCount,
    ad.MinCommentCount,
    CASE 
        WHEN ad.PostCount > 0 THEN ROUND(AVG(ad.AvgReputation) OVER (), 2)
        ELSE NULL 
    END AS OverallAvgReputation
FROM 
    AggregateData ad
ORDER BY 
    FIELD(ad.ScoreCategory, 'High Score', 'Medium Score', 'Low Score');

### Explanation:

1. **Common Table Expressions (CTEs)**: 
   - The first CTE, `RankedPosts`, retrieves posts created within the last year, along with their comments, ranks them per user based on score, and counts the comments for each post.
   - The second CTE, `PostStats`, calculates owner reputation and categorizes posts based on scores.
   - The third CTE, `AggregateData`, computes aggregate statistics per score category.

2. **NULL Logic**: 
   - The query utilizes `COALESCE` to handle potential NULL values in the reputation column and ensures `CommentCount` defaults to 0 when NULL.

3. **Window Functions**: 
   - Uses `ROW_NUMBER()` for ranking and `AVG(..) OVER()` for calculating overall average reputation across groups.

4. **CASE Statements**: 
   - Categorizes scores into three groups and computes minimum comment counts while avoiding NULLs.

5. **Sorting**: 
   - The results are ordered by the custom score categories.

This showcases various SQL constructs, including elaborate aggregations, conditional logic, ranking, and CTEs, creating a comprehensive and performance-intensive query suitable for benchmarking scenarios.
