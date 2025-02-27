WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(b.BadgeCount, 0) AS OwnerBadgeCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS BadgeCount
        FROM 
            Badges
        GROUP BY 
            UserId
    ) b ON u.Id = b.UserId
    WHERE 
        p.CreationDate > (CURRENT_TIMESTAMP - INTERVAL '1 year')
),
TopPosts AS (
    SELECT 
        rp.*,
        pt.Name AS PostTypeName,
        ht.Name AS HistoryTypeName,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS CommentCount
    FROM 
        RankedPosts rp
    JOIN 
        PostTypes pt ON rp.PostTypeId = pt.Id
    LEFT JOIN 
        PostHistory hp ON hp.PostId = rp.PostId
    LEFT JOIN 
        PostHistoryTypes ht ON hp.PostHistoryTypeId = ht.Id
    WHERE 
        rp.Rank <= 5
)
SELECT 
    PostId,
    Title,
    ViewCount,
    CreationDate,
    Score,
    OwnerDisplayName,
    OwnerBadgeCount,
    CommentCount,
    PostTypeName,
    HistoryTypeName
FROM 
    TopPosts
ORDER BY 
    PostTypeName, Score DESC;
