
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATEADD(MONTH, -6, '2024-10-01 12:34:56') 
        AND p.PostTypeId = 1 
),
TaggedPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        STRING_AGG(t.TagName, ', ') AS Tags,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.RankScore
    FROM 
        RankedPosts rp
    CROSS APPLY (SELECT value AS TagName FROM STRING_SPLIT(rp.Title, ' ')) t
    GROUP BY 
        rp.Id, rp.Title, rp.OwnerDisplayName, rp.CreationDate, rp.Score, rp.ViewCount, rp.AnswerCount, rp.RankScore
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.Tags
FROM 
    TaggedPosts tp
WHERE 
    tp.RankScore <= 10
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;
