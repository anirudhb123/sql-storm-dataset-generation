
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        LISTAGG(t.TagName, ', ') WITHIN GROUP (ORDER BY t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        LATERAL FLATTEN(INPUT => SPLIT(SUBSTR(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS tag_name ON tag_name.VALUE IS NOT NULL
    JOIN 
        Tags t ON t.TagName = tag_name.VALUE
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
    JOIN 
        LATERAL FLATTEN(INPUT => SPLIT(SUBSTR(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS tag_name ON tag_name.VALUE IS NOT NULL
    JOIN 
        Tags t ON t.TagName = tag_name.VALUE
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        t.TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        LISTAGG(DISTINCT pht.Name, ', ') WITHIN GROUP (ORDER BY pht.Name) AS HistoryTypes,
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
    TopTags rt ON rt.TagName IN (SELECT value FROM TABLE(FLATTEN(INPUT => SPLIT(rp.Tags, ', '))))
WHERE 
    rp.Rank <= 5 
ORDER BY 
    rp.ViewCount DESC, 
    rp.Score DESC;
