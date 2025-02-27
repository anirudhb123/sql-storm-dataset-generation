
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY u.Reputation ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0 
),
TagStatistics AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag,
        COUNT(*) AS PostCount,
        AVG(p.ViewCount) AS AvgViewCount,
        AVG(p.Score) AS AvgScore
    FROM 
        Posts p
    INNER JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        AvgViewCount,
        AvgScore,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagStatistics
    WHERE 
        PostCount > 5 
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    tt.Tag AS PopularTag,
    tt.PostCount AS TagPostCount,
    tt.AvgViewCount AS TagAvgViewCount,
    tt.AvgScore AS TagAvgScore
FROM 
    RankedPosts rp
JOIN 
    TopTags tt ON rp.Tags LIKE CONCAT('%', tt.Tag, '%')
WHERE 
    rp.Rank <= 10 
ORDER BY 
    rp.OwnerDisplayName, tt.TagRank, rp.Score DESC;
