WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank,
        COALESCE(c.UserDisplayName, 'Community User') AS OwnerDisplayName
    FROM 
        Posts p
    LEFT JOIN 
        Users c ON p.OwnerUserId = c.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.CreationDate,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
PostCommentStats AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount,
        SUM(Score) AS TotalCommentScore
    FROM 
        Comments
    GROUP BY 
        PostId
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryActions
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.ViewCount,
    tp.Score,
    tp.CreationDate,
    tp.OwnerDisplayName,
    COALESCE(pcs.CommentCount, 0) AS CommentCount,
    COALESCE(pcs.TotalCommentScore, 0) AS TotalCommentScore,
    COALESCE(phi.HistoryActions, 'No History') AS HistoryActions
FROM 
    TopPosts tp
LEFT JOIN 
    PostCommentStats pcs ON tp.PostId = pcs.PostId
LEFT JOIN 
    PostHistoryInfo phi ON tp.PostId = phi.PostId
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;

This query utilizes several SQL constructs including:

- Common Table Expressions (CTEs) for encapsulating complex selections (`RankedPosts`, `TopPosts`, `PostCommentStats`, `PostHistoryInfo`).
- `ROW_NUMBER()` window function to rank posts based on their score and view count.
- Aggregation functions such as `COUNT()` and `SUM()` to retrieve comment statistics.
- `STRING_AGG()` function to concatenate post history action types into a single string.
- `COALESCE()` to handle NULL values and provide meaningful defaults.
- Outer joins to include posts potentially having no comments or history actions, thus demonstrating NULL logic. 

The output shows detailed statistics for the top posts in the last year, along with comments and history information, ordered by post score and views.
