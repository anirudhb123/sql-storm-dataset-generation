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
    WHERE p.PostTypeId = 1 -- We're interested in Questions only
    AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
TagCounts AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName
    FROM RankedPosts
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
JOIN TopTags tt ON tt.TagName = ANY(string_to_array(substring(rp.Tags, 2, length(rp.Tags)-2), '><'))
WHERE rp.PostRank <= 5 -- Limit to top 5 posts per user
AND tt.TagRank <= 10 -- Limit to top 10 tags
ORDER BY rp.OwnerDisplayName, tt.TagUsage DESC;
