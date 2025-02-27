
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        p.Tags,
        @row_num := IF(@current_user_id = p.OwnerUserId, @row_num + 1, 1) AS PostRank,
        @current_user_id := p.OwnerUserId
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    CROSS JOIN (SELECT @row_num := 0, @current_user_id := NULL) r
    WHERE p.PostTypeId = 1 
    AND p.CreationDate >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
    ORDER BY p.OwnerUserId, p.Score DESC
),
TagCounts AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(TRIM(BOTH '}' FROM TRIM(BOTH '{' FROM Tags)), '><', numbers.n), '>', -1)) AS TagName
    FROM RankedPosts 
    INNER JOIN (
        SELECT a.N + b.N * 10 + 1 n
        FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a
        CROSS JOIN (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
        ORDER BY n
    ) numbers ON CHAR_LENGTH(TRIM(BOTH '{' FROM Tags)) - CHAR_LENGTH(REPLACE(TRIM(BOTH '{' FROM Tags), '><', '')) >= numbers.n - 1
),
TagFrequency AS (
    SELECT 
        TagName,
        COUNT(*) AS TagUsage
    FROM TagCounts
    GROUP BY TagName
),
TopTags AS (
    SELECT 
        TagName,
        TagUsage,
        @tag_rank := @tag_rank + 1 AS TagRank
    FROM TagFrequency
    CROSS JOIN (SELECT @tag_rank := 0) r
    ORDER BY TagUsage DESC
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.ViewCount,
    rp.Score,
    tt.TagName,
    tt.TagUsage
FROM RankedPosts rp
JOIN TopTags tt ON FIND_IN_SET(tt.TagName, TRIM(BOTH '{}' FROM rp.Tags)) > 0
WHERE rp.PostRank <= 5 
AND tt.TagRank <= 10 
ORDER BY rp.OwnerDisplayName, tt.TagUsage DESC;
