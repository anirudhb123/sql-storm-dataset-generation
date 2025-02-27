
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        p.Tags,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0 
        AND p.CreationDate >= CAST(DATEADD(year, -1, '2024-10-01 12:34:56') AS DATETIME)
),
TagPopularity AS (
    SELECT
        value AS Tag
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><') AS TagArray
    WHERE 
        PostTypeId = 1
        AND Tags IS NOT NULL
),
PopularTags AS (
    SELECT 
        Tag,
        COUNT(*) AS TagFrequency
    FROM 
        TagPopularity
    GROUP BY 
        Tag
    ORDER BY 
        TagFrequency DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
),
PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.ViewCount,
        rp.Score,
        rp.Tags
    FROM 
        RankedPosts rp
    JOIN 
        PopularTags pt ON rp.Tags LIKE '%' + pt.Tag + '%'
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.OwnerDisplayName,
    pp.ViewCount,
    pp.Score,
    pt.Tag
FROM 
    PopularPosts pp
CROSS JOIN 
    PopularTags pt
ORDER BY 
    pt.Tag, pp.Score DESC;
