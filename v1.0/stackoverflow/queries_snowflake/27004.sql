
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        LATERAL FLATTEN(input => SPLIT(REPLACE(REPLACE(p.Tags, '<', ''), '>', ''), '>')) AS t ON TRUE
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56') AND p.ViewCount > 100
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, u.DisplayName, p.Score, p.ViewCount, p.PostTypeId
),
TopPosts AS (
    SELECT 
        PostId, Title, OwnerDisplayName, Score, ViewCount, CommentCount, Tags
    FROM 
        RankedPosts
    WHERE 
        ScoreRank <= 10
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    LISTAGG(tag, ', ') AS TagsList
FROM 
    TopPosts tp
JOIN 
    LATERAL FLATTEN(input => tp.Tags) AS tag ON TRUE
GROUP BY 
    tp.Title, tp.OwnerDisplayName, tp.Score, tp.ViewCount, tp.CommentCount
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
