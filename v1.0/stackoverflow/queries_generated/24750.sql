WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.Score IS NOT NULL
),
ModeratedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        (SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END)) AS NetVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.Score, rp.ViewCount, rp.CreationDate, u.DisplayName
    HAVING 
        COUNT(c.Id) < 5
),
ClosedPosts AS (
    SELECT 
        ph.PostId, 
        COUNT(*) AS CloseReasonCount,
        STRING_AGG(DISTINCT crt.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON ph.Comment::int = crt.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId
)
SELECT 
    mp.PostId,
    mp.Title,
    mp.Score,
    mp.ViewCount,
    mp.OwnerName,
    COALESCE(cp.CloseReasonCount, 0) AS CloseReasonCount,
    COALESCE(cp.CloseReasons, 'None') AS CloseReasons,
    CASE 
        WHEN mp.NetVotes > 50 THEN 'Popular' 
        WHEN mp.NetVotes <= 50 AND mp.NetVotes > 0 THEN 'Moderately Liked' 
        WHEN mp.NetVotes < 0 THEN 'Disliked' 
        ELSE 'Neutral' 
    END AS Popularity
FROM 
    ModeratedPosts mp
LEFT JOIN 
    ClosedPosts cp ON mp.PostId = cp.PostId
WHERE 
    mp.Rank <= 5
ORDER BY 
    mp.Score DESC NULLS LAST, 
    mp.ViewCount DESC NULLS LAST;

In this query, we combined several SQL constructs to achieve a complex performance benchmark while handling potential semantic nuances:
1. **Common Table Expressions (CTEs)**: Defined several CTEs to organize data by ranking, moderation, and closed posts.
2. **Window Functions**: Used `ROW_NUMBER()` to rank posts based on score within their post type.
3. **Outer Joins**: Used `LEFT JOIN` to include users, comments, and votes, ensuring posts are still included even without associated data.
4. **Aggregations**: Counted comments and votes, calculating net votes and addressing potential `NULL` values via `COALESCE`.
5. **String Aggregation**: Collected unique close reasons using `STRING_AGG`.
6. **Conditional Logic**: Implemented a `CASE` statement to classify posts based on their net votes, considering unusual logic patterns.
7. **Filter Logic**: Included a `HAVING` clause to limit moderated posts to less than five comments, introducing an obscure edge case.
8. **Complex Ordering**: Last, we ordered by score and view count while gracefully handling `NULL` values. 

This query could serve as a benchmark for testing performance with multiple joins, aggregations, and computations.
