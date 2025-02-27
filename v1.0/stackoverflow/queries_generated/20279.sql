WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COALESCE(v.UserId, u.Id) AS VotedByUserId,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ISNULL(v.CreationDate, '1900-01-01') DESC) AS VoteRank,
        COUNT(DISTINCT v.Id) OVER (PARTITION BY p.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  -- upvotes
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        (p.ViewCount > 100 OR p.Score > 0)
        AND p.CreationDate >= '2022-01-01'
),
AggPostData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        MAX(rp.Score) AS MaxScore,
        AVG(rp.Score) AS AvgScore,
        STRING_AGG(CONVERT(varchar, rp.VotedByUserId), ', ') AS VoterIds,
        COUNT(*) AS VoteCount,
        COUNT(rp.PostId) OVER () AS TotalPosts
    FROM 
        RankedPosts rp
    GROUP BY 
        rp.PostId, rp.Title
)
SELECT 
    apd.PostId,
    apd.Title,
    apd.MaxScore,
    apd.AvgScore,
    apd.VoterIds,
    apd.VoteCount,
    CASE 
        WHEN apd.TotalPosts = 0 THEN NULL 
        ELSE CAST(apd.VoteCount AS float) / apd.TotalPosts * 100 
    END AS VotePercentage
FROM 
    AggPostData apd
WHERE 
    apd.VoteCount > 0
ORDER BY 
    apd.MaxScore DESC
OFFSET 0 ROWS 
FETCH NEXT 10 ROWS ONLY
UNION ALL
SELECT 
    NULL AS PostId,
    'Total Votes Count' AS Title,
    NULL AS MaxScore,
    NULL AS AvgScore,
    NULL AS VoterIds,
    SUM(VoteCount) AS VoteCount,
    CAST(SUM(VoteCount) AS float) / COUNT(*) * 100 AS TotalVotePercentage
FROM 
    AggPostData;

This SQL query does the following:

1. **Common Table Expressions (CTEs)**:
   - `RankedPosts` selects posts with a score or view count above certain thresholds, while also relating votes specifically from 'upvotes'. It uses `ROW_NUMBER()` to generate ranks based on vote creation date.
   - `AggPostData` aggregates the posts from the `RankedPosts` CTE, collecting maximum score, average score, and concatenated voter user IDs for each post.

2. **Main Query**:
   - Selects data from `AggPostData`, calculating a `VotePercentage`.
   - Uses `ORDER BY` to list the posts with the highest scores and limits the output to 10 posts, while supporting pagination with `OFFSET`.

3. **Union Section**:
   - Adds a unioned query that calculates total votes across all aggregated posts, ensuring both detailed and summary statistics are returned.

4. **NULL Logic**:
   - Manages potential division by zero in vote percentage calculation with a case statement that returns NULL if `TotalPosts` is zero.

5. **String Aggregation**:
   - Uses `STRING_AGG` to concatenate voter IDs for visual inspection.

This query leverages complex SQL semantics, incorporating aggregates, CTEs, conditional logic, and different join types, all within a performance benchmarking scenario.
