WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS OwnerPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 AND
        p.Score > 0 
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        OwnerName,
        CommentCount,
        OwnerPostRank
    FROM 
        RankedPosts
    WHERE 
        OwnerPostRank <= 5
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.OwnerName,
    tp.CommentCount,
    COALESCE(b.BadgeCount, 0) AS BadgeCount
FROM 
    TopPosts tp
LEFT JOIN (
    SELECT 
        UserId, 
        COUNT(*) AS BadgeCount 
    FROM 
        Badges 
    GROUP BY 
        UserId
) b ON tp.OwnerName = b.UserId
ORDER BY 
    tp.Score DESC
LIMIT 10;


