WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 END), 0) AS VoteScore,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY (p.Score + COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 END), 0)) DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id
),
TopPosts AS (
    SELECT 
        rp.*
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.VoteScore,
    tp.CommentCount,
    tp.BadgeCount,
    u.DisplayName AS OwnerDisplayName
FROM 
    TopPosts tp
JOIN 
    Users u ON tp.OwnerUserId = u.Id
ORDER BY 
    tp.Score DESC, tp.VoteScore DESC, tp.ViewCount DESC;
