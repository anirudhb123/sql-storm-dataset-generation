
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        pb.BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT UserId, COUNT(*) AS BadgeCount
        FROM Badges
        GROUP BY UserId
    ) pb ON u.Id = pb.UserId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(YEAR, 1, 0) 
        AND p.PostTypeId = 1
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        Score, 
        ViewCount, 
        OwnerDisplayName, 
        BadgeCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
),
CommentStatistics AS (
    SELECT 
        PostId,
        COUNT(c.Id) AS CommentCount,
        AVG(DATALENGTH(c.Text)) AS AvgCommentLength
    FROM 
        Comments c
    GROUP BY 
        PostId
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.OwnerDisplayName,
    tp.BadgeCount,
    ISNULL(cs.CommentCount, 0) AS CommentCount,
    ISNULL(cs.AvgCommentLength, 0) AS AvgCommentLength
FROM 
    TopPosts tp
LEFT JOIN 
    CommentStatistics cs ON tp.PostId = cs.PostId
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
