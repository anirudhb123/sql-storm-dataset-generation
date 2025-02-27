WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS Owner,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE()) 
        AND (p.Body IS NOT NULL AND p.Body != '')
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS ClosedDate,
        cr.Name AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.CreationDate,
    CASE 
        WHEN cp.ClosedDate IS NOT NULL THEN DATEDIFF(day, cp.ClosedDate, GETDATE()) 
        ELSE NULL 
    END AS DaysSinceClosed,
    rp.CommentCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpVotes,  -- Count of UpVotes
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 3) AS DownVotes   -- Count of DownVotes
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.RecentPostRank = 1 -- Only the most recent post by owner
ORDER BY 
    COALESCE(DaysSinceClosed, 0) DESC,  -- Sort by days since post closed,
    rp.Score DESC;  -- then by score descending

This query does the following:

1. **CTE (Common Table Expression)** `RankedPosts`: Retrieves a list of posts from the last year, along with comment counts and ranks the posts by their creation date for each user.
2. **CTE `ClosedPosts`**: Retrieves details about closed posts and their close reasons.
3. **Final Selection**: Combines the results of both CTEs, calculating the days since a post was closed, and counting upvotes and downvotes using subqueries.
4. **Sorting**: Results are ordered based on how long it has been since they were closed and their score.

This provides a comprehensive overview of recent posts, particularly useful for performance benchmarking in scenarios involving activity and closure dynamics of user-contributed content.
