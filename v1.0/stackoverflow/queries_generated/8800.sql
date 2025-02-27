WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS UpvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 -- Upvotes only
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days' 
        AND p.ViewCount > 100
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        Score, 
        ViewCount, 
        OwnerDisplayName,
        Rank 
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.OwnerDisplayName,
    ph.Comment,
    ph.CreationDate AS HistoryDate
FROM 
    TopPosts tp
JOIN 
    PostHistory ph ON tp.PostId = ph.PostId
WHERE 
    ph.PostHistoryTypeId IN (10, 11, 12, 14) -- Post closed, reopened, deleted, locked
ORDER BY 
    tp.Score DESC, ph.CreationDate DESC
LIMIT 50;
