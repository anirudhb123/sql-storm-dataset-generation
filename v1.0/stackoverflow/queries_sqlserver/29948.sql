
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
    AND 
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
),
TaggedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.ViewCount,
        rp.Score,
        t.TagName
    FROM 
        RankedPosts rp
    JOIN 
        Posts p ON rp.PostId = p.Id
    CROSS APPLY (SELECT value AS tag FROM STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '> <')) AS tag_table
    JOIN 
        Tags t ON t.TagName = tag_table.tag
    WHERE 
        t.Count > 10 
),
PostMetrics AS (
    SELECT 
        tp.OwnerDisplayName,
        COUNT(tp.PostId) AS TotalPosts,
        AVG(tp.ViewCount) AS AvgViews,
        SUM(tp.Score) AS TotalScore,
        STRING_AGG(DISTINCT tp.TagName, ', ') AS PopularTags
    FROM 
        TaggedPosts tp
    GROUP BY 
        tp.OwnerDisplayName
)
SELECT 
    pm.OwnerDisplayName,
    pm.TotalPosts,
    pm.AvgViews,
    pm.TotalScore,
    pm.PopularTags
FROM 
    PostMetrics pm
ORDER BY 
    pm.TotalScore DESC 
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
