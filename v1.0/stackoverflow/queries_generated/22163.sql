WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        p.Tags,
        COALESCE(NULLIF(p.Body, ''), 'No content provided') AS BodyContent,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > CURRENT_TIMESTAMP - INTERVAL '30 days'
    GROUP BY 
        p.Id
),
ClosedPostHistories AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate,
        STRING_AGG(DISTINCT c.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    JOIN 
        CloseReasonTypes c ON ph.Comment::int = c.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed and Reopened
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.BodyContent,
    rp.Score,
    rp.CommentCount,
    rp.UpvoteCount,
    rp.DownvoteCount,
    cp.LastClosedDate,
    cp.CloseReasons,
    CASE 
        WHEN rp.Rank = 1 THEN 'Most Recent'
        ELSE 'Older Post'
    END AS PostRankCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPostHistories cp ON rp.PostId = cp.PostId
WHERE 
    (rp.CommentCount > 5 OR rp.Score >= 10)
    AND (cp.LastClosedDate IS NULL OR cp.LastClosedDate < CURRENT_TIMESTAMP - INTERVAL '15 days')
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC
LIMIT 50;

### Explanation:
1. **Common Table Expressions (CTEs)**: Two CTEs, `RankedPosts` and `ClosedPostHistories`, are created to handle calculations and aggregations separately.
   - `RankedPosts`: This aggregates post data, calculates the rank of posts by their creation date for each user and counts comments and vote types.
   - `ClosedPostHistories`: This aggregates closed post histories and retrieves the last closed date along with the close reasons.

2. **Using COALESCE and NULLIF**: It ensures that if the body of a post is an empty string, it will return a default message instead of NULL.

3. **Aggregations**: The query counts both the number of comments and upvotes/downvotes using `SUM` combined with `CASE` for conditional counting within the main post table.

4. **Filtering**: The main selection from the `RankedPosts` CTE filters to show posts in the last 30 days, ensuring a dynamic analysis of recent activity.

5. **Sorting and Limiting**: The results are sorted by post score and creation date, limiting the output to the top 50 results based on the score, providing a succinct view of high-impact posts in the database.

6. **Bizarre Corner Cases**: Usage of `STRING_AGG` for close reasons from JSON formatted data demonstrates handling of complex data types, providing consolidated strings for a post's historical context.

This query serves as a complex benchmark that challenges performance due to multiple joins, aggregations, and filtering criteria while showcasing the capabilities of SQL syntax and functions.
