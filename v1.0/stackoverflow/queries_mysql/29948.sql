
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
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
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
    JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS tag
         FROM Posts p 
         JOIN (SELECT @row := @row + 1 AS n FROM 
               (SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) t, 
               (SELECT @row := 0) r) n 
         WHERE n.n <= CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) + 1) AS tag_table ON TRUE
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
        GROUP_CONCAT(DISTINCT tp.TagName ORDER BY tp.TagName ASC SEPARATOR ', ') AS PopularTags
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
LIMIT 10;
