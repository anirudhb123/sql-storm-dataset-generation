WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(cm.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankWithinUser
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments cm ON p.Id = cm.PostId
    WHERE 
        p.PostTypeId = 1 AND -- Only questions
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Within the last year
    GROUP BY 
        p.Id, u.DisplayName
), TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankWithinUser = 1
)

SELECT 
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.OwnerDisplayName,
    tp.CommentCount,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    ARRAY_AGG(DISTINCT bt.Name) AS BadgeNames
FROM 
    TopPosts tp
LEFT JOIN 
    Badges b ON tp.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = b.UserId)
JOIN 
    (SELECT DISTINCT UserId, Name FROM Badges) bt ON b.UserId = bt.UserId
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, tp.OwnerDisplayName, tp.CommentCount
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC
LIMIT 10;
