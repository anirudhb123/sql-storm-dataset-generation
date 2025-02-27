
WITH ProcessedTags AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag
    FROM Posts p
    JOIN (
        SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
        UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
    ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
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
        @rank := @rank + 1 AS Rank
    FROM TagUsage, (SELECT @rank := 0) r
    WHERE UsageCount > 5 
    ORDER BY UsageCount DESC
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        GROUP_CONCAT(DISTINCT t.Tag) AS Tags
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
    SUBSTRING_INDEX(tp.Tags, ',', 1) AS MostUsedTag
FROM TopPosts tp
JOIN TopTags t ON FIND_IN_SET(t.Tag, tp.Tags) > 0
WHERE t.Rank <= 5 
ORDER BY tp.Score DESC, tp.ViewCount DESC;
