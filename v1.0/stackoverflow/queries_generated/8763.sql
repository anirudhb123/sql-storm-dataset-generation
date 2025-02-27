WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
), TopPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        OwnerDisplayName,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    tp.*, 
    pt.Name AS PostTypeName, 
    COALESCE(SUM(b.Class = 1), 0) AS GoldBadges, 
    COALESCE(SUM(b.Class = 2), 0) AS SilverBadges, 
    COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges
FROM 
    TopPosts tp
LEFT JOIN 
    Users u ON tp.OwnerDisplayName = u.DisplayName
LEFT JOIN 
    Badges b ON u.Id = b.UserId
JOIN 
    PostTypes pt ON tp.PostId = pt.Id
GROUP BY 
    tp.PostId, tp.Title, tp.Score, tp.ViewCount, tp.OwnerDisplayName
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
