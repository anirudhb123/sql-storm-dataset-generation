
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
        value AS Tag,
        COUNT(*) AS PostCount,
        AVG(p.ViewCount) AS AvgViewCount,
        AVG(p.Score) AS AvgScore
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') AS TagValue
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        value
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
    TopTags tt ON rp.Tags LIKE '%' + tt.Tag + '%'
WHERE 
    rp.Rank <= 10 
ORDER BY 
    rp.OwnerDisplayName, tt.TagRank, rp.Score DESC;
