
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Author,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(YEAR, 1, 0) 
        AND p.Score > 0
), 
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Author,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
), 
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
), 
PostBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)

SELECT 
    tp.Title,
    tp.Author,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    ISNULL(pc.CommentCount, 0) AS CommentCount,
    ISNULL(pb.BadgeCount, 0) AS BadgeCount
FROM 
    TopPosts tp
LEFT JOIN 
    PostComments pc ON tp.PostId = pc.PostId
LEFT JOIN 
    PostBadges pb ON tp.Author = (SELECT TOP 1 DisplayName FROM Users WHERE Id = pb.UserId)
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC;
