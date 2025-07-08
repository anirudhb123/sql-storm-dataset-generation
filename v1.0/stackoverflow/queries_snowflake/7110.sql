
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
CommentsCounts AS (
    SELECT 
        PostId, 
        COUNT(*) AS CommentCount
    FROM 
        Comments 
    GROUP BY 
        PostId
),
BadgesCounts AS (
    SELECT 
        UserId, 
        COUNT(*) AS BadgeCount
    FROM 
        Badges 
    GROUP BY 
        UserId
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    COALESCE(cc.CommentCount, 0) AS CommentCount,
    COALESCE(bc.BadgeCount, 0) AS BadgeCount
FROM 
    TopPosts tp
LEFT JOIN CommentsCounts cc ON tp.PostId = cc.PostId
LEFT JOIN BadgesCounts bc ON bc.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
