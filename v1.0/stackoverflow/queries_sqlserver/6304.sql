
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56')
), 
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        Score, 
        ViewCount, 
        AnswerCount, 
        CommentCount, 
        FavoriteCount, 
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
), 
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(p.Tags, '><') AS tag 
    JOIN 
        Tags t ON t.TagName = tag.value
    WHERE 
        tag.value <> ''
    GROUP BY 
        p.Id
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.CommentCount,
    tp.FavoriteCount,
    tp.OwnerDisplayName,
    pt.Tags
FROM 
    TopPosts tp
LEFT JOIN 
    PostTags pt ON tp.PostId = pt.PostId
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
