WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 YEAR'
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp 
    WHERE 
        rp.PostRank <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.OwnerDisplayName,
    tp.CommentCount,
    pt.Name AS PostTypeName,
    COALESCE(badgeCount.BadgeCount, 0) AS UserBadgeCount
FROM 
    TopPosts tp
JOIN 
    PostTypes pt ON tp.PostTypeId = pt.Id
LEFT JOIN (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount 
    FROM 
        Badges b
    WHERE 
        b.Date >= CURRENT_DATE - INTERVAL '1 YEAR'
    GROUP BY 
        b.UserId
) badgeCount ON badgeCount.UserId = tp.OwnerUserId
ORDER BY 
    tp.ViewCount DESC, tp.Score DESC;
