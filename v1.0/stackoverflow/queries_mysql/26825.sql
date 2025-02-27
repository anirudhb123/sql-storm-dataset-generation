
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
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
),

TagStats AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '>', numbers.n), '>', -1)) AS TagName, 
        COUNT(*) AS TagUsageCount
    FROM 
        Posts
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL 
         SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '>', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TagName
),

TopTags AS (
    SELECT 
        TagName,
        TagUsageCount,
        RANK() OVER (ORDER BY TagUsageCount DESC) AS TagRank
    FROM 
        TagStats
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    rp.Tags,
    tt.TagName AS MostPopularTag,
    tt.TagUsageCount AS MostPopularTagCount
FROM 
    RankedPosts rp
JOIN 
    TopTags tt ON rp.Tags LIKE CONCAT('%', tt.TagName, '%') 
WHERE 
    rp.Rank <= 5 
ORDER BY 
    rp.Tags, rp.Score DESC;
