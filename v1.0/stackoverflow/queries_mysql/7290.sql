
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankByViews,
        p.Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', numbers.n), '>', -1) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    INNER JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
    LIMIT 5
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.CreationDate,
    rp.OwnerDisplayName,
    pts.Tag,
    ph.LastEditDate,
    ph.CloseReopenCount
FROM 
    RankedPosts rp
JOIN 
    PostHistorySummary ph ON rp.PostId = ph.PostId
JOIN 
    PopularTags pts ON pts.Tag IN (SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Tags, '>', numbers.n), '>', -1))
JOIN 
    (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) numbers ON CHAR_LENGTH(rp.Tags) - CHAR_LENGTH(REPLACE(rp.Tags, '>', '')) >= numbers.n - 1
WHERE 
    rp.RankByViews <= 10
ORDER BY 
    rp.ViewCount DESC, ph.LastEditDate DESC;
