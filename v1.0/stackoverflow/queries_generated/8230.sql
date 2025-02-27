WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankByView
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Author,
        rp.Score,
        rp.ViewCount,
        rp.RankByScore,
        rp.RankByView,
        pt.Name AS PostType
    FROM 
        RankedPosts rp
    JOIN 
        PostTypes pt ON rp.Title LIKE '%' + pt.Name + '%'
    WHERE 
        rp.RankByScore <= 3 OR rp.RankByView <= 3
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Author,
    tp.PostType,
    tp.Score,
    tp.ViewCount,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = tp.PostId) AS CommentCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = tp.PostId AND v.VoteTypeId = 2) AS UpVoteCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = tp.PostId AND v.VoteTypeId = 3) AS DownVoteCount
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
