WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS Owner,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        AVG(v.Value) AS AverageVoteValue
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (
            SELECT 
                PostId,
                CASE 
                    WHEN VoteTypeId = 2 THEN 1 
                    WHEN VoteTypeId = 3 THEN -1 
                    ELSE 0 
                END AS Value
            FROM 
                Votes
        ) v ON p.Id = v.PostId
    GROUP BY 
        p.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10  -- Post Closed
    GROUP BY 
        ph.PostId
),
TopClosedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Owner,
        cp.LastClosedDate,
        rp.CommentCount
    FROM 
        RankedPosts rp
    JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
    WHERE 
        rp.PostRank <= 5  -- Top 5 posts by score
)
SELECT 
    tcp.Title,
    tcp.Owner,
    tcp.LastClosedDate,
    CASE 
        WHEN tcp.CommentCount > 10 THEN 'Active Discussion'
        ELSE 'Low Activity' 
    END AS DiscussionStatus,
    COALESCE(NULLIF(tcp.LastClosedDate, (CURRENT_TIMESTAMP - INTERVAL '30 days')), 'Not Recently Closed') AS ClosureSummary
FROM 
    TopClosedPosts tcp
ORDER BY 
    tcp.LastClosedDate DESC;

This complex SQL query demonstrates various advanced SQL concepts, including:
- Common Table Expressions (CTEs) for modular queries and readability.
- Window functions to rank posts by score while counting comments.
- Outer joins to gather data even when related records might not exist (e.g., users without comments or votes).
- The use of NULL logic to handle conditional outputs gracefully (with `COALESCE` and `NULLIF`).
- Complicated predicates to categorize discussions based on the comment count.
- An interesting closure summary that checks the recency of closure within a specific timeframe.
