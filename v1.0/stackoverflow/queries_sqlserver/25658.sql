
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS PostRank,
        p.Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
),
TagCounts AS (
    SELECT 
        TRIM(value) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '> <')
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TRIM(value)
),
PopularTags AS (
    SELECT 
        Tag,
        TagCount,
        RANK() OVER (ORDER BY TagCount DESC) AS PopularityRank
    FROM 
        TagCounts
    WHERE 
        TagCount > 10 
),
PostHistoryAnalysis AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount,
        STRING_AGG(DISTINCT pht.Name, ', ') AS ActionTypes
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
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.OwnerDisplayName,
    rp.Reputation,
    pt.Tag AS PopularTag,
    pha.HistoryCount,
    pha.ActionTypes
FROM 
    RankedPosts rp
LEFT JOIN 
    PopularTags pt ON pt.Tag IN (SELECT TRIM(value) FROM STRING_SPLIT(SUBSTRING(rp.Tags, 2, LEN(rp.Tags) - 2), '> <'))
LEFT JOIN 
    PostHistoryAnalysis pha ON pha.PostId = rp.PostId
WHERE 
    rp.PostRank = 1 
ORDER BY 
    rp.ViewCount DESC, 
    rp.Reputation DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
