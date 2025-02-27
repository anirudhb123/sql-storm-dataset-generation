WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        CreationDate,
        Tags,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.Tags,
    tp.OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    SUM(v.VoteTypeId = 2) AS UpVoteCount,
    SUM(v.VoteTypeId = 3) AS DownVoteCount
FROM 
    TopPosts tp
LEFT JOIN 
    Comments c ON tp.PostId = c.PostId
LEFT JOIN 
    Votes v ON tp.PostId = v.PostId
GROUP BY 
    tp.PostId, tp.Title, tp.Score, tp.ViewCount, tp.Tags, tp.OwnerDisplayName
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
