WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT c.Name, ', ') AS CloseReasons,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes c ON ph.Comment::int = c.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
    GROUP BY 
        ph.PostId
),
FinalPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.UpVotes - rp.DownVotes AS NetVotes,
        COALESCE(cp.CloseReasons, 'No Close Reasons') AS CloseReasons,
        COALESCE(cp.CloseCount, 0) AS CloseCount,
        CASE 
            WHEN rp.Rank = 1 THEN 'Latest Post'
            ELSE 'Older Post'
        END AS PostLabel
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
)
SELECT 
    fp.PostId,
    fp.Title AS PostTitle,
    fp.CreationDate,
    fp.Score,
    fp.NetVotes,
    fp.CloseReasons,
    fp.CloseCount,
    CASE 
        WHEN fp.NetVotes < 0 THEN 'Needs Attention'
        WHEN fp.Score > 50 THEN 'Highly Voted'
        ELSE 'Regular Activity'
    END AS PostActivity
FROM 
    FinalPosts fp
WHERE 
    fp.CloseCount = 0 -- Filter to show only posts that are not closed
ORDER BY 
    fp.Score DESC NULLS LAST, 
    fp.CreationDate ASC
FETCH FIRST 20 ROWS ONLY;

This SQL query does the following:

1. **Common Table Expressions (CTEs)**:
   - `RankedPosts`: Ranks the posts by their creation date per user, calculates upvotes and downvotes.
   - `ClosedPosts`: Gathers the closed posts and counts the closure reasons for those posts, using string aggregation and grouping.
   - `FinalPosts`: Combines the results of the previous two CTEs to have a comprehensive overview of posts, including a label based on their rank.

2. **Complex Logic**: The net votes are calculated, and conditional logic is applied to provide descriptive labels for posts and their statuses based on voting outcomes and closure status.

3. **String Expressions and NULL Logic**: Uses string aggregation to show close reasons or indicates if there are none and ensures that any calculations involving NULL are handled with COALESCE.

4. **Filters and Order**: Filters out closed posts in the final selection and orders based on score and creation date.

5. **Limitation**: It limits the output to the top 20 results to control the size of the result set.

This elaborate query includes multiple SQL concepts and constructs, aiming to deliver powerful insights into post performance over the last year.
