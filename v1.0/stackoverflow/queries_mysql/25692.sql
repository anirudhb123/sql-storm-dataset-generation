
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
ProcessedTags AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n),'><', -1) AS Tag
    FROM 
        Posts p
    INNER JOIN (
        SELECT a.N + b.N * 10 + 1 n
        FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
             (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
    ) n 
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1
    WHERE 
        p.Tags IS NOT NULL
),
TagCounts AS (
    SELECT 
        Tag,
        COUNT(*) AS TagFrequency
    FROM 
        ProcessedTags
    GROUP BY 
        Tag
),
PopularTags AS (
    SELECT 
        Tag,
        TagFrequency,
        ROW_NUMBER() OVER (ORDER BY TagFrequency DESC) AS PopularityRank
    FROM 
        TagCounts
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rp.CreationDate,
    rp.OwnerDisplayName,
    pt.Tag AS MostPopularTag
FROM 
    RankedPosts rp
JOIN 
    PopularTags pt ON pt.PopularityRank = 1
WHERE 
    rp.RankByViews <= 5 
ORDER BY 
    rp.OwnerDisplayName, 
    rp.ViewCount DESC;
