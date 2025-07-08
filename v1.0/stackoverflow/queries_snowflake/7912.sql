
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
    AND 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
PopularTags AS (
    SELECT 
        TRIM(value) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts,
        LATERAL FLATTEN(input => SPLIT(Tags, '><')) AS tag
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TRIM(value)
    ORDER BY 
        TagCount DESC
    LIMIT 5
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.Score,
    rp.CreationDate,
    pt.TagName,
    pt.TagCount
FROM 
    RankedPosts rp
LEFT JOIN 
    PopularTags pt ON rp.Title ILIKE '%' || pt.TagName || '%'
WHERE 
    rp.Rank <= 3
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC;
