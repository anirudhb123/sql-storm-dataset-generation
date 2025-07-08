
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2023-10-01' 
        AND p.PostTypeId = 1  
),

AggregatedTags AS (
    SELECT 
        TRIM(REGEXP_SUBSTR(t.value, '[^<>]+')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p,
        LATERAL FLATTEN(INPUT => SPLIT(TRIM(BOTH '{}' FROM p.Tags), '>')) AS t
    WHERE 
        p.CreationDate >= '2023-10-01'
        AND p.PostTypeId = 1
    GROUP BY 
        TagName
),

TopTags AS (
    SELECT 
        TagName,
        TagCount,
        RANK() OVER (ORDER BY TagCount DESC) AS TagRank
    FROM 
        AggregatedTags
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.CreationDate,
    rp.ViewCount,
    rp.OwnerDisplayName,
    tt.TagName,
    tt.TagCount
FROM 
    RankedPosts rp
LEFT JOIN 
    TopTags tt ON rp.Tags ILIKE '%' || tt.TagName || '%'
WHERE 
    rp.ViewRank <= 5  
ORDER BY 
    rp.ViewCount DESC, 
    rp.CreationDate DESC;
