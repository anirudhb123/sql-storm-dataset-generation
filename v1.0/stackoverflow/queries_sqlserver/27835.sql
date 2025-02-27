
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
    AND p.CreationDate >= CAST(DATEADD(YEAR, -1, '2024-10-01') AS DATE)
),
TagCounts AS (
    SELECT 
        value AS TagName
    FROM RankedPosts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><')
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
JOIN TopTags tt ON tt.TagName IN (SELECT value FROM STRING_SPLIT(SUBSTRING(rp.Tags, 2, LEN(rp.Tags) - 2), '><'))
WHERE rp.PostRank <= 5 
AND tt.TagRank <= 10 
ORDER BY rp.OwnerDisplayName, tt.TagUsage DESC;
