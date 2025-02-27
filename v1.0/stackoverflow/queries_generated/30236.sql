WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,  -- Upvotes count
        SUM(v.VoteTypeId = 3) AS DownVotes  -- Downvotes count
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Filter to posts from the last year
    GROUP BY 
        p.Id, p.Title, u.DisplayName, p.Score, p.CreationDate
), MostCommentedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        rp.CreationDate
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10 -- Top 10 posts by score
    ORDER BY 
        rp.CommentCount DESC
), PostHistoryAggregated AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstEditDate,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (4, 5, 6) THEN 1 END) AS TotalEdits  -- Edit types
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Title,
    p.OwnerDisplayName,
    p.CommentCount,
    p.UpVotes,
    p.DownVotes,
    ph.FirstEditDate,
    ph.LastEditDate,
    ph.TotalEdits,
    CASE 
        WHEN ph.FirstEditDate IS NOT NULL THEN 'Edited'
        ELSE 'Not Edited'
    END AS EditStatus,
    COALESCE(ph.TotalEdits, 0) AS EditCount
FROM 
    MostCommentedPosts p
LEFT JOIN 
    PostHistoryAggregated ph ON p.PostId = ph.PostId
ORDER BY 
    p.CommentCount DESC, 
    p.UpVotes DESC;
