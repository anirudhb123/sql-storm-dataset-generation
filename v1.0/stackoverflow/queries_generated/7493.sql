WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS Author,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpvoteCount,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Author,
        rp.CommentCount,
        rp.UpvoteCount,
        rp.DownvoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
)
SELECT 
    tp.*, 
    JSON_AGG(JSON_BUILD_OBJECT('Id', bh.Id, 'Name', pht.Name, 'Comment', bh.Comment, 'Date', bh.CreationDate)) AS History
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistory bh ON tp.PostId = bh.PostId
LEFT JOIN 
    PostHistoryTypes pht ON bh.PostHistoryTypeId = pht.Id
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, tp.Author, tp.CommentCount, tp.UpvoteCount, tp.DownvoteCount
ORDER BY 
    tp.Score DESC;
