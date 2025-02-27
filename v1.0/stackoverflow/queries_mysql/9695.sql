
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.Reputation AS OwnerReputation,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.Reputation
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerReputation
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.OwnerReputation,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    GROUP_CONCAT(DISTINCT b.Name ORDER BY b.Name SEPARATOR ', ') AS Badges
FROM 
    TopPosts tp
LEFT JOIN 
    Badges b ON tp.OwnerReputation = b.UserId
GROUP BY 
    tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, tp.OwnerReputation
ORDER BY 
    tp.Score DESC, tp.CreationDate ASC;
