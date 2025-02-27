
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS Owner,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Owner
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 10
)
SELECT 
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.Owner,
    COUNT(c.Id) AS CommentCount,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
FROM 
    TopPosts tp
LEFT JOIN 
    Comments c ON tp.PostId = c.PostId
LEFT JOIN 
    Votes v ON tp.PostId = v.PostId AND v.VoteTypeId = 8 
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, tp.Owner
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
