
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        p.Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
FilteredTags AS (
    SELECT 
        pt.TagName,
        COUNT(pt.TagName) AS TagCount
    FROM 
        Posts p,
        LATERAL FLATTEN(INPUT => SPLIT(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS pt
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year'
    GROUP BY 
        pt.TagName
    HAVING 
        COUNT(pt.TagName) > 5
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rp.CreationDate AS PostCreationDate,
    rp.OwnerDisplayName,
    ft.TagName,
    ft.TagCount
FROM 
    RankedPosts rp
JOIN 
    FilteredTags ft ON ft.TagName IN (SELECT VALUE FROM TABLE(FLATTEN(INPUT => SPLIT(SUBSTRING(rp.Tags, 2, LENGTH(rp.Tags) - 2), '><')))))
WHERE 
    rp.Rank = 1
ORDER BY 
    rp.ViewCount DESC, 
    ft.TagCount DESC
LIMIT 10;
