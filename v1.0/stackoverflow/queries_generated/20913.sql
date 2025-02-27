WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS UpVoteCount,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0) AS DownVoteCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
),

PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.UpVoteCount,
        rp.DownVoteCount,
        (rp.UpVoteCount - rp.DownVoteCount) AS NetVotes,
        CASE 
            WHEN rp.Score > 5 THEN 'Hot'
            WHEN rp.Score BETWEEN 3 AND 5 THEN 'Trending'
            ELSE 'Normal'
        END AS Popularity
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1
),

ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Post Closed and Post Reopened
    GROUP BY 
        ph.PostId, ph.CreationDate
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.UpVoteCount,
    ps.DownVoteCount,
    ps.NetVotes,
    ps.Popularity,
    COALESCE(cp.CloseReasons, 'No closure reasons') AS CloseReasons
FROM 
    PostStatistics ps
LEFT JOIN 
    ClosedPosts cp ON ps.PostId = cp.PostId
WHERE 
    ps.Popularity = 'Hot'
ORDER BY 
    ps.ViewCount DESC, ps.CreationDate DESC
LIMIT 100;

### Explanation:
1. **RankedPosts CTE**: Uses the `ROW_NUMBER()` window function to rank posts within their `PostTypeId` based on `CreationDate` descending. It also counts upvotes and downvotes using correlated subqueries.

2. **PostStatistics CTE**: Calculates the popularity of the posts based on their score and provides a net voting count by subtracting downvotes from upvotes.

3. **ClosedPosts CTE**: Gathers information about posts that were closed or reopened, aggregating the close reasons into a string.

4. **Final Selection**: The main query retrieves posts classified as "Hot" based on their popularity. It combines data from `PostStatistics` and `ClosedPosts` using a left join, ensuring that even posts without closure information are included. Results are ordered by view count and creation date with a limit of 100 results to optimize performance for benchmarking.
