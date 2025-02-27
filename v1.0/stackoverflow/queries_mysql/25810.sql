
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
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, ',', numbers.n), ',', -1)) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, ',', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TagName 
    ORDER BY 
        TagCount DESC
    LIMIT 5
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
            GROUP_CONCAT(pt.TagName SEPARATOR ', ') 
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
