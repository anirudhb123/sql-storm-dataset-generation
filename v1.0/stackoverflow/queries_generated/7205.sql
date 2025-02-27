WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.VoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 10
)
SELECT 
    tp.Title,
    tp.ViewCount,
    tp.Score,
    tp.CommentCount,
    tp.OwnerDisplayName,
    COALESCE(SUM(b.Class = 1), 0) AS GoldBadges,
    COALESCE(SUM(b.Class = 2), 0) AS SilverBadges,
    COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges
FROM 
    TopPosts tp
LEFT JOIN 
    Badges b ON tp.OwnerDisplayName = b.UserId
GROUP BY 
    tp.PostId, tp.Title, tp.ViewCount, tp.Score, tp.CommentCount, tp.OwnerDisplayName
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
