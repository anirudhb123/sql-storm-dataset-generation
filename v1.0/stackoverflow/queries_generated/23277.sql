WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' AND 
        p.Score IS NOT NULL
),
PostAggregates AS (
    SELECT 
        p.Id,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpvoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownvoteCount,
        MAX(b.Date) AS LatestBadgeDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    GROUP BY 
        p.Id
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS CloseReasons,
        MIN(ph.CreationDate) AS FirstClosedDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Post Closed or Post Reopened
    GROUP BY 
        ph.PostId
),
FinalOutput AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        COALESCE(pa.CommentCount, 0) AS CommentCount,
        COALESCE(pa.UpvoteCount, 0) AS UpvoteCount,
        COALESCE(pa.DownvoteCount, 0) AS DownvoteCount,
        ch.FirstClosedDate,
        ch.CloseReasons,
        CASE 
            WHEN ch.CloseReasons IS NOT NULL THEN 'Closed'
            ELSE 'Active'
        END AS PostStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostAggregates pa ON rp.PostId = pa.Id
    LEFT JOIN 
        ClosedPostHistory ch ON rp.PostId = ch.PostId
)
SELECT 
    Title,
    ViewCount,
    Score,
    CommentCount,
    UpvoteCount,
    DownvoteCount,
    PostStatus,
    FirstClosedDate,
    CloseReasons
FROM 
    FinalOutput
WHERE 
    PostStatus = 'Closed' OR 
    (PostStatus = 'Active' AND ViewCount > 1000)
ORDER BY 
    Score DESC, 
    ViewCount DESC;

This SQL query employs several advanced constructs:

1. **Common Table Expressions (CTEs)**: Used to organize the query logically with `RankedPosts`, `PostAggregates`, and `ClosedPostHistory`.
2. **Window Functions**: Used `ROW_NUMBER()` to rank posts based on score and view count.
3. **Aggregration Functions**: Utilizes `COUNT`, `STRING_AGG`, and conditional aggregates (using `FILTER`) to get various metrics.
4. **NULL Logic**: Makes use of `COALESCE` to replace NULL with zeros for counts.
5. **Complex Predicates**: The `WHERE` clause applies both time-based filters and conditions based on post status.
6. **String Aggregation**: Employed to collate multiple close reason types that correspond to a post.
7. **Order By**: Final result sorted by score and view count to highlight the most significant posts.

This query offers insight into post engagement while taking into account their closure status, creating a multifaceted performance benchmark.
