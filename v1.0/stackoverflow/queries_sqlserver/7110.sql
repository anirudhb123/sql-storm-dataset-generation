
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
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(year, 1, 0)
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
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title, 
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        tp.OwnerDisplayName,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(b.BadgeCount, 0) AS BadgeCount
    FROM 
        TopPosts tp
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) c ON tp.PostId = c.PostId
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS BadgeCount
        FROM 
            Badges 
        GROUP BY 
            UserId
    ) b ON b.UserId = (SELECT TOP 1 OwnerUserId FROM Posts WHERE Id = tp.PostId)
)
SELECT 
    pd.Title,
    pd.OwnerDisplayName,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.CommentCount,
    pd.BadgeCount
FROM 
    PostDetails pd
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC;
