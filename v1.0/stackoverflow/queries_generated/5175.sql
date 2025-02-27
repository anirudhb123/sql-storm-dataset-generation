WITH RankedPosts AS (
    SELECT 
        p.Id as PostId,
        p.Title,
        u.DisplayName as OwnerDisplayName,
        p.CreationDate,
        p.LastActivityDate,
        COALESCE(p.ViewCount, 0) AS ViewCount,
        COALESCE(p.Score, 0) AS Score,
        COUNT(c.Id) as CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COALESCE(p.Score, 0) DESC, COALESCE(p.ViewCount, 0) DESC) as Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.CreationDate, p.LastActivityDate
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        CreationDate,
        LastActivityDate,
        ViewCount,
        Score,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.CreationDate,
    tp.LastActivityDate,
    tp.ViewCount,
    tp.Score,
    tp.CommentCount,
    COALESCE(b.Name, 'No Badge') as BadgeName
FROM 
    TopPosts tp
LEFT JOIN 
    Badges b ON tp.OwnerDisplayName = b.UserId 
WHERE 
    tp.Score > (SELECT AVG(Score) FROM Posts)
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
