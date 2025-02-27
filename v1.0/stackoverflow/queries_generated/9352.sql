WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id 
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 -- Upvotes only
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.OwnerDisplayName,
        rp.Score,
        rp.ViewCount,
        rp.Rank
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.Score,
    tp.ViewCount,
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
) c ON tp.Id = c.PostId
LEFT JOIN (
    SELECT 
        UserId,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Badges b
    JOIN 
        Users u ON b.UserId = u.Id
    WHERE 
        u.Reputation > 100
    GROUP BY 
        UserId
) b ON tp.OwnerDisplayName = b.UserId
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC;
