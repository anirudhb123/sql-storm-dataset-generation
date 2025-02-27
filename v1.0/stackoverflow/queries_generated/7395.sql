WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY v.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days' 
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.VoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1
    ORDER BY 
        rp.VoteCount DESC, rp.Score DESC
    LIMIT 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.OwnerDisplayName,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    tp.VoteCount,
    json_agg(DISTINCT json_build_object('UserId', v.UserId, 'CreationDate', v.CreationDate)) AS Votes
FROM 
    TopPosts tp
LEFT JOIN 
    Votes v ON tp.PostId = v.PostId
GROUP BY 
    tp.PostId, tp.Title, tp.OwnerDisplayName, tp.CreationDate, tp.Score, tp.ViewCount, tp.CommentCount, tp.VoteCount
ORDER BY 
    tp.VoteCount DESC;
