WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(v.Id) AS UpvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 -- UpMod
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        rp.RankScore,
        rp.CommentCount,
        rp.UpvoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankScore <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.CreationDate,
    tp.CommentCount,
    tp.UpvoteCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation,
    (SELECT COUNT(*) 
     FROM PostHistory ph 
     WHERE ph.PostId = tp.PostId AND ph.PostHistoryTypeId IN (10, 11, 12)) AS HistoryCount
FROM 
    TopPosts tp
JOIN 
    Users u ON tp.PostId = u.Id
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
