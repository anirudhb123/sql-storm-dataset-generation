WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
), TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        Score, 
        ViewCount, 
        OwnerDisplayName, 
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    tp.Title, 
    tp.Score, 
    tp.ViewCount, 
    tp.CommentCount, 
    tp.OwnerDisplayName, 
    STRING_AGG(t.TagName, ', ') AS Tags
FROM 
    TopPosts tp
LEFT JOIN 
    (SELECT 
         Id, 
         TagName 
     FROM 
         Tags) t ON tp.PostId = t.ExcerptPostId
GROUP BY 
    tp.PostId, tp.Title, tp.Score, tp.ViewCount, tp.CommentCount, tp.OwnerDisplayName
ORDER BY 
    tp.Score DESC;
