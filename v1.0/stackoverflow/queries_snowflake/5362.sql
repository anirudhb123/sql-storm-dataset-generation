
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS Author,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2023-10-01 12:34:56'::timestamp
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Author
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
CommentCounts AS (
    SELECT 
        PostId, 
        COUNT(*) AS CommentCount 
    FROM 
        Comments 
    GROUP BY 
        PostId
),
BadgeCounts AS (
    SELECT 
        b.UserId, 
        COUNT(*) AS BadgeCount 
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    COALESCE(c.CommentCount, 0) AS CommentCount,
    COALESCE(b.BadgeCount, 0) AS BadgeCount
FROM 
    TopPosts tp
LEFT JOIN 
    CommentCounts c ON tp.PostId = c.PostId
LEFT JOIN 
    BadgeCounts b ON tp.Author = (SELECT DisplayName FROM Users WHERE Id = b.UserId)
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
