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
        p.CreationDate >= NOW() - INTERVAL '6 months' 
        AND p.PostTypeId = 1 -- Considering only Questions
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
        rp.AnswerCount
    FROM 
        RankedPosts rp
    JOIN 
        LATERAL (SELECT unnest(string_to_array(rp.Title, ' ')) AS TagName) t ON t.TagName IS NOT NULL
    GROUP BY 
        rp.Id
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
