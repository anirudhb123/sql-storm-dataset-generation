
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
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 
    AND p.CreationDate >= DATEADD(year, -1, '2024-10-01')
),
TagCounts AS (
    SELECT 
        TRIM(value) AS TagName
    FROM RankedPosts,
    LATERAL SPLIT_TO_TABLE(SUBSTR(Tags, 2, LENGTH(Tags) - 2), '><') AS value
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
        ROW_NUMBER() OVER (ORDER BY TagUsage DESC) AS TagRank
    FROM TagFrequency
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
JOIN TopTags tt ON tt.TagName IN (SELECT TRIM(value) FROM LATERAL SPLIT_TO_TABLE(SUBSTR(rp.Tags, 2, LENGTH(rp.Tags) - 2), '><') AS value)
WHERE rp.PostRank <= 5 
AND tt.TagRank <= 10 
ORDER BY rp.OwnerDisplayName, tt.TagUsage DESC;
