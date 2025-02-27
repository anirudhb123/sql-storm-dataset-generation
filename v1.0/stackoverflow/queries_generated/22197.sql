WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS rn,
        COUNT(v.Id) OVER (PARTITION BY p.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '365 days'
),

PostHistories AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        MAX(ph.CreationDate) AS LastEdited
    FROM 
        PostHistory ph
    INNER JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
),

ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.Comment,
        ph.CreationDate AS ClosedOn
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.VoteCount,
    rp.UpVotes,
    rp.DownVotes,
    COALESCE(ph.HistoryCount, 0) AS HistoryCount,
    ph.HistoryTypes,
    cp.ClosedOn
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistories ph ON rp.PostId = ph.PostId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    (rp.rn <= 5 OR cp.ClosedOn IS NOT NULL)  -- Show top 5 posts or any closed posts
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC
LIMIT 50;
This SQL query features multiple advanced constructs:

1. **CTEs**: `RankedPosts`, `PostHistories`, and `ClosedPosts` efficiently summarize data from multiple tables.
2. **Window Functions**: Used to rank posts by their score and count votes, enabling a deeper analysis of their performance.
3. **Outer Joins**: To gather histories and closed posts without losing any relevant posts.
4. **String Aggregation**: Collects history types in a readable format.
5. **Complicated Filtering Logic**: Returning either the top-scoring posts or closed posts, showcasing dynamic criteria based on the context.
6. **NULL Logic**: `COALESCE` is used to ensure that posts without history still return a count of zero.

The query aims to retrieve insightful performance metrics of posts while considering their historical changes and closed status, which could be useful for benchmarking different post types over the past year.
