WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpvoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (CURRENT_DATE - INTERVAL '1 year')
        AND p.Score IS NOT NULL
),
ClosedPosts AS (
    SELECT 
        p.Id AS ClosedPostId,
        p.Title, 
        ph.CreationDate AS CloseDate,
        ph.Comment AS CloseReason
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    WHERE 
        ph.CreationDate >= (CURRENT_DATE - INTERVAL '1 year')
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.UpvoteCount,
        rp.DownvoteCount,
        CASE 
            WHEN rp.Score IS NULL THEN 'No Score'
            WHEN rp.Score > 0 THEN 'Positive'
            WHEN rp.Score < 0 THEN 'Negative'
            ELSE 'Zero Score'
        END AS ScoreCategory
    FROM 
        RankedPosts rp
),
Combined AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.Score,
        ps.ViewCount,
        ps.UpvoteCount,
        ps.DownvoteCount,
        ps.ScoreCategory,
        COALESCE(cp.CloseReason, 'Not Closed') AS ClosureStatus
    FROM 
        PostStatistics ps
    LEFT JOIN 
        ClosedPosts cp ON ps.PostId = cp.ClosedPostId
)
SELECT 
    *,
    (DownvoteCount * 1.0 / NULLIF(UpvoteCount, 0)) AS DownvoteToUpvoteRatio,
    LEAD(CreationDate) OVER (ORDER BY CreationDate) AS NextPostCreationDate
FROM 
    Combined
WHERE 
    ScoreCategory != 'Zero Score'
ORDER BY 
    Score DESC,
    ClosureStatus ASC
LIMIT 50;

This SQL query is designed to extract performance-related insights from a fictional Stack Overflow schema. It includes several advanced SQL constructs:

1. **Common Table Expressions (CTEs)**: Used to first create temporary result sets for ranked posts, closed posts, and post statistics.
2. **Window Functions**: Fetching running totals and aggregations related to votes and post ranking.
3. **Filters**: Applying conditions on votes and date ranges.
4. **NULL Handling**: Use of `COALESCE` and `NULLIF` to manage potential divisions by zero and provide default values for NULL columns.
5. **Complicated Expressions**: Creating a score category based on the post scores and calculating the downvote-to-upvote ratio.
6. **Ordinal Functions**: The `LEAD` function is used to get the creation date of the next post, allowing comparisons of posts over different timeframes.
7. **Outer Joins**: Used to capture posts that may or may not have been closed, preserving their data in the result set.
8. **String Expressions**: Calculations and transformations applied to produce readable categories and formats.

This results in an insightful dataset that allows for comprehensive benchmarking and analysis of posts, considering engagement metrics and moderation actions.
