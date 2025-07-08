
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
        TRIM(REGEXP_SUBSTR(p.Tags, '[^><]+', 1, seq.seq)) AS Tag
    FROM 
        Posts p
    JOIN 
        (SELECT ROW_NUMBER() OVER () AS seq FROM TABLE(GENERATOR(ROWCOUNT => 1000))) seq ON 
        seq.seq <= LEN(REGEXP_REPLACE(p.Tags, '[^><]', '')) - LEN(REPLACE(REPLACE(p.Tags, '><', ''), '<', '')) + 1
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
