
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank,
        ARRAY_AGG(t.TagName) AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        LATERAL FLATTEN(input => SPLIT(p.Tags, '>')) AS tag_id ON tag_id.VALUE IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag_id.VALUE
    WHERE 
        p.CreationDate > DATEADD(year, -1, '2024-10-01 12:34:56'::timestamp)
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.AnswerCount, u.DisplayName, p.PostTypeId
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        ViewCount, 
        Score, 
        AnswerCount,
        OwnerDisplayName,
        Tags
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.ViewCount,
    tp.Score,
    tp.AnswerCount,
    tp.OwnerDisplayName,
    tp.Tags
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC;
