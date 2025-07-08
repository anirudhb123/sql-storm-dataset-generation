
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
        AND p.CreationDate >= '2023-10-01 12:34:56'::timestamp - INTERVAL '1 year' 
),
TagPopularity AS (
    SELECT 
        TRIM(REGEXP_SUBSTR(tag, '[^><]+', 1, seq)) AS Tag
    FROM (
        SELECT 
            Tags,
            SEQ4() AS seq
        FROM 
            Posts
        WHERE 
            PostTypeId = 1 
            AND Tags IS NOT NULL
    ),
    LATERAL FLATTEN(INPUT => SPLIT(Tags, '><')) AS tag
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
    LIMIT 10
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
        PopularTags pt ON POSITION(pt.Tag IN rp.Tags) > 0
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
