WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount, 
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        DENSE_RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RankByType
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.ViewCount, 
        rp.Score, 
        rp.CommentCount, 
        rp.UpVotes, 
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByType <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    COUNT(DISTINCT b.Id) AS BadgeCount
FROM 
    TopPosts tp
LEFT JOIN 
    Badges b ON tp.PostId = b.UserId
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.ViewCount, tp.Score, tp.CommentCount, tp.UpVotes, tp.DownVotes
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;
