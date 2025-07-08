
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATEADD(year, -1, '2024-10-01')
),
PopularTags AS (
    SELECT 
        TRIM(value) AS TagName
    FROM 
        Posts,
        LATERAL FLATTEN(input => SPLIT(SUBSTR(Tags, 2, LEN(Tags)-2), '><')) AS value
    WHERE 
        PostTypeId = 1 
),
TagPopularity AS (
    SELECT 
        TagName,
        COUNT(*) AS TagCount
    FROM 
        PopularTags
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.Score,
    rp.ViewCount,
    tp.TagName,
    tp.TagCount
FROM 
    RankedPosts rp
JOIN 
    TagPopularity tp ON tp.TagName IN (TRIM(value) FROM LATERAL FLATTEN(input => SPLIT(SUBSTR(rp.Tags, 2, LEN(rp.Tags)-2), '><'))))
WHERE 
    rp.PostRank = 1
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
