
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND p.Score > 0 
),

TagStats AS (
    SELECT 
        TRIM(value) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts,
        LATERAL FLATTEN(input => SPLIT(Tags, '><')) AS value
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TRIM(value)
)

SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.ViewCount,
    r.Score,
    r.OwnerDisplayName,
    r.Tags,
    ts.TagName,
    ts.PostCount
FROM 
    RankedPosts r
JOIN 
    TagStats ts ON ts.TagName IN (SELECT TRIM(value) FROM LATERAL FLATTEN(input => SPLIT(r.Tags, '><')))
WHERE 
    r.Rank = 1 
ORDER BY 
    r.Score DESC, r.ViewCount DESC
LIMIT 100;
