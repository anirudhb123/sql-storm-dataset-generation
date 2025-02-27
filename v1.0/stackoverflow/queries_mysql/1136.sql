
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        @row_number := IF(@postTypeId = p.PostTypeId, @row_number + 1, 1) AS Rank,
        @postTypeId := p.PostTypeId,
        COALESCE(r.BadgeCount, 0) AS BadgeCount
    FROM 
        Posts p
    CROSS JOIN (SELECT @row_number := 0, @postTypeId := NULL) AS vars
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS BadgeCount
        FROM 
            Badges
        GROUP BY 
            UserId
    ) r ON p.OwnerUserId = r.UserId
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        Score, 
        ViewCount, 
        CreationDate, 
        BadgeCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(CASE WHEN c.UserId IS NOT NULL THEN 1 END) AS CommentCount,
        GROUP_CONCAT(c.Text SEPARATOR ' | ') AS CommentTexts
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.CreationDate,
    tp.BadgeCount,
    COALESCE(pc.CommentCount, 0) AS TotalComments,
    pc.CommentTexts
FROM 
    TopPosts tp
LEFT JOIN 
    PostComments pc ON tp.PostId = pc.PostId
WHERE 
    tp.BadgeCount > 0 OR tp.ViewCount > 100
ORDER BY 
    tp.Score DESC,
    tp.CreationDate DESC
LIMIT 10;
