WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.LastActivityDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(u.DisplayName, 'Community') AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Posts p
        LEFT JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) -- Count only upvotes and downvotes
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, p.LastActivityDate, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        rp.LastActivityDate,
        rp.Rank,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.TotalBounties
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
        AND rp.CreationDate >= CURRENT_DATE - INTERVAL '30 days' -- Filter for the last 30 days
),
PostClosureDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT ph.Comment, '; ') AS CloseReasons
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) -- Closure details
    GROUP BY 
        ph.PostId
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Score,
    fp.ViewCount,
    fp.CreationDate,
    fp.LastActivityDate,
    fp.OwnerDisplayName,
    fp.CommentCount,
    fp.TotalBounties,
    COALESCE(pcd.CloseReasons, 'Open') AS CloseReasons
FROM 
    FilteredPosts fp
    LEFT JOIN PostClosureDetails pcd ON fp.PostId = pcd.PostId
ORDER BY 
    fp.Score DESC, 
    fp.ViewCount DESC;

This query achieves the following:

1. **CTEs**: It uses Common Table Expressions (CTEs) to break down the complex logic:
   - `RankedPosts` ranks posts by score and aggregates the total comments and bounties.
   - `FilteredPosts` selects the top 10 posts from the last 30 days.
   - `PostClosureDetails` summarizes closure reasons for posts.

2. **Outer Join**: It performs a LEFT JOIN to include closure reasons even if there are none.

3. **Window Functions**: It calculates rankings based on scores.

4. **Aggregations**: Uses aggregate functions to count comments and sum bounties, and also string aggregation for closure reasons.

5. **Filters**: Applies filters to limit results based on recent activity and specific criteria.

6. **NULL Logic**: Incorporates COALESCE to manage posts without closure reasons. 

This query can be utilized for performance benchmarking, ensuring that various constructs function optimally when dealing with potentially large datasets.
