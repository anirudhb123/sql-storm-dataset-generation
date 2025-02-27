
WITH ProcessedTags AS (
    SELECT 
        p.Id AS PostId,
        value AS Tag
    FROM Posts p
    CROSS APPLY STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags)-2), '><') 
    WHERE p.PostTypeId = 1 
),
TagUsage AS (
    SELECT 
        Tag,
        COUNT(*) AS UsageCount
    FROM ProcessedTags
    GROUP BY Tag
),
TopTags AS (
    SELECT 
        Tag,
        UsageCount,
        ROW_NUMBER() OVER (ORDER BY UsageCount DESC) AS Rank
    FROM TagUsage
    WHERE UsageCount > 5 
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        STRING_AGG(DISTINCT t.Tag, ',') AS Tags
    FROM Posts p
    JOIN ProcessedTags t ON p.Id = t.PostId
    WHERE p.PostTypeId = 1 AND p.Score > 10
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    t.Tag AS MostUsedTag
FROM TopPosts tp
JOIN TopTags t ON t.Tag IN (SELECT value FROM STRING_SPLIT(tp.Tags, ','))
WHERE t.Rank <= 5 
ORDER BY tp.Score DESC, tp.ViewCount DESC;
