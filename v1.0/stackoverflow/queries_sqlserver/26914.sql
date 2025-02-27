
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        STRING_AGG(t.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    CROSS APPLY STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '>') AS tag_name
    JOIN 
        Tags t ON t.TagName = tag_name.value
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '>') AS tag_name
    JOIN 
        Tags t ON t.TagName = tag_name.value
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        t.TagName
    ORDER BY 
        TagCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
),
PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        MIN(ph.CreationDate) AS FirstHistoryDate,
        COUNT(ph.Id) AS HistoryCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.Tags,
    rp.OwnerDisplayName,
    pga.HistoryTypes,
    pga.FirstHistoryDate,
    pga.HistoryCount,
    rt.TagName AS TopTag
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryAggregates pga ON rp.PostId = pga.PostId
JOIN 
    TopTags rt ON rt.TagName IN (SELECT value FROM STRING_SPLIT(rp.Tags, ', '))
WHERE 
    rp.Rank <= 5 
ORDER BY 
    rp.ViewCount DESC, 
    rp.Score DESC;
