WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
        SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpVotes,
        SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS DownVotes 
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.Score IS NOT NULL 
        AND p.ViewCount > 0
),
ClosedPostHistories AS (
    SELECT 
        ph.PostId, 
        ph.CreationDate AS ClosedDate,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::INT = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId, ph.CreationDate
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.UpVotes,
        rp.DownVotes,
        CASE 
            WHEN ch.ClosedDate IS NOT NULL THEN 'Closed'
            ELSE 'Active'
        END AS PostStatus,
        COALESCE(ch.CloseReasons, 'No Close Reasons') AS CloseReasons
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPostHistories ch ON rp.PostId = ch.PostId
    WHERE 
        rp.rn = 1
)
SELECT 
    FR.PostId,
    FR.Title,
    FR.CreationDate,
    FR.ViewCount,
    FR.Score,
    FR.UpVotes,
    FR.DownVotes,
    FR.PostStatus,
    FR.CloseReasons,
    CONCAT(
        'Post ID: ', FR.PostId,
        ', Title: ', FR.Title,
        ', Status: ', FR.PostStatus
    ) AS PostDescription
FROM 
    FinalResults FR
WHERE 
    FR.ViewCount > (
        SELECT AVG(ViewCount) FROM Posts
    ) 
    AND FR.Score > (
        SELECT AVG(Score) FROM Posts
    )
ORDER BY 
    FR.CreationDate DESC
FETCH FIRST 50 ROWS ONLY;

This SQL query does the following:

1. **Common Table Expressions (CTEs)**:
   - `RankedPosts`: Assigns a row number to posts based on creation date per post type, calculates upvotes and downvotes for each post.
   - `ClosedPostHistories`: Aggregates closed post histories, capturing their closed date and associated close reasons.
   - `FinalResults`: Joins the previous CTEs to determine the status of each post (Active or Closed) based on the existence of a closed date.

2. **Filters**: The main selection queries posts that have more views than the average and a higher score than the average, ensuring we only retrieve impactful posts.

3. **Output Enhancements**: The final select adds a formatted string `PostDescription` that concatenates relevant details about each post for easy readability.

4. **Ordering**: The results are ordered by the creation date of the posts in descending order.

5. **NULL Logic and COALESCE**: Returns a default message for posts that have no close reasons.

This query is complicated due to its use of multiple subqueries, CTEs, window functions, and conditional logic, designed for performance benchmarking and analysis of posts on the Stack Overflow schema.
