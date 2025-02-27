
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS TotalPosts 
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
), 
PopularTags AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(Tags, ',') 
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        value 
    ORDER BY 
        TagCount DESC
    OFFSET 0 ROWS 
    FETCH NEXT 5 ROWS ONLY
), 
PostHistoryCounts AS (
    SELECT 
        ph.PostId, 
        COUNT(*) AS EditCount,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (6, 2) THEN 1 ELSE 0 END) AS TagOrBodyEdits
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.Score,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.Rank,
    rp.TotalPosts,
    pht.EditCount,
    pht.TagOrBodyEdits,
    (
        SELECT 
            STRING_AGG(pt.TagName, ', ') 
        FROM 
            PopularTags pt 
        WHERE 
            pt.TagCount > 1
    ) AS PopularTagsUsed
FROM 
    RankedPosts rp
JOIN 
    PostHistoryCounts pht ON rp.PostId = pht.PostId
WHERE 
    rp.Rank <= 3  
ORDER BY 
    rp.CreationDate DESC;
