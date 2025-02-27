WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.OwnerUserId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS TotalPosts
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only questions
        AND p.CreationDate >= DATEADD(YEAR, -1, GETDATE())  -- Created in the last year
),
UpvoteStats AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownvoteCount
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostCloseHistory AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  -- only looking for closed/reopened history
    GROUP BY 
        ph.PostId
)
SELECT  
    rp.PostId,
    rp.Title,
    rp.Score,
    UPPER(CONCAT('User ID: ', CAST(rp.OwnerUserId AS VARCHAR))) AS FormattedOwnerId,
    ISNULL(ups.UpvoteCount, 0) AS TotalUpvotes,
    ISNULL(ups.DownvoteCount, 0) AS TotalDownvotes,
    ISNULL(pc.CommentCount, 0) AS TotalComments,
    rp.CreationDate,
    CASE 
        WHEN pc.CommentCount > 10 THEN 'Hot Topic'
        ELSE 'Cold Topic'
    END AS TopicStatus,
    DATEDIFF(DAY, rp.CreationDate, GETDATE()) AS DaysSinceCreation,
    DENSE_RANK() OVER (ORDER BY rp.Score DESC) AS GlobalPostRank,
    COALESCE(ch.ClosedDate, 'N/A') AS ClosureStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    UpvoteStats ups ON rp.PostId = ups.PostId
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
LEFT JOIN 
    PostCloseHistory ch ON rp.PostId = ch.PostId
WHERE 
    rp.ScoreRank = 1  -- Highest scored post per user
    AND (DaysSinceCreation < 30 OR TotalComments > 5)  -- Active or engaging topics
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC;

### Description of the Query

1. **CTEs**:
   - **RankedPosts**: Ranks posts by score for each user, filtering for questions created in the last year.
   - **UpvoteStats**: Aggregates upvotes and downvotes for each post.
   - **PostComments**: Counts comments for each post.
   - **PostCloseHistory**: Tracks the closure date of posts when they have been closed.

2. **Main Query**:
   - Joins the CTEs to retrieve scores, user IDs, and other relevant statistics.
   - Uses `ISNULL` to handle potential NULL values in counts.
   - Implemented `CASE` logic to define topics as 'Hot' or 'Cold' based on comment count.
   - Filters and orders results based on score and other engagement metrics.

3. **Unique Constructs**:
   - Uses `UPPER` and `CONCAT` to form a string display for user IDs.
   - Implements various window functions to rank and count data.
   - Uses `COALESCE` to ensure closure status provides meaningful information even if a post wasn't closed.

This query is designed for performance benchmarking and handles complex aggregations, joins, string manipulation, and handling of NULL values in a detailed manner, showcasing the SQL capabilities in handling complex business logic and reporting scenarios.
