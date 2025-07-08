
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerName,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATEADD(year, -1, CURRENT_DATE)
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerName,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
CommentCount AS (
    SELECT 
        PostId, 
        COUNT(*) AS CommentCount 
    FROM 
        Comments 
    GROUP BY 
        PostId
),
AnswerCount AS (
    SELECT 
        ParentId AS PostId, 
        COUNT(*) AS AnswerCount 
    FROM 
        Posts 
    WHERE 
        PostTypeId = 2 
    GROUP BY 
        ParentId
),
BadgeCount AS (
    SELECT 
        UserId, 
        COUNT(*) AS BadgeCount 
    FROM 
        Badges 
    GROUP BY 
        UserId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.OwnerName,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    COALESCE(c.CommentCount, 0) AS CommentCount,
    COALESCE(a.AnswerCount, 0) AS AnswerCount,
    COALESCE(b.BadgeCount, 0) AS BadgeCount
FROM 
    TopPosts tp
LEFT JOIN 
    CommentCount c ON tp.PostId = c.PostId
LEFT JOIN 
    AnswerCount a ON tp.PostId = a.PostId
LEFT JOIN 
    BadgeCount b ON tp.OwnerName = (SELECT DisplayName FROM Users WHERE Id = b.UserId)
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
