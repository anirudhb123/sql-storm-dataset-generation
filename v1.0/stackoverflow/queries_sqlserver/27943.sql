
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
        LTRIM(RTRIM(value)) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(Tags, '><')
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        LTRIM(RTRIM(value))
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
    TagStats ts ON ts.TagName IN (SELECT value FROM STRING_SPLIT(r.Tags, '><'))
WHERE 
    r.Rank = 1 
ORDER BY 
    r.Score DESC, r.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
