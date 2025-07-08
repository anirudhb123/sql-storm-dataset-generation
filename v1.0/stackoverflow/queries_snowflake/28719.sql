
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0 
),
TagStatistics AS (
    SELECT 
        TRIM(value) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts,
        LATERAL SPLIT_TO_TABLE(LEFT(Tags, LENGTH(Tags) - 2), '><') AS value
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
),
RecentEdits AS (
    SELECT 
        ph.PostId,
        COUNT(DISTINCT ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        MAX(ph.UserDisplayName) AS LastEditedBy
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 24) 
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate,
    rp.OwnerDisplayName,
    ts.TagName,
    ts.TagCount,
    re.EditCount,
    re.LastEditDate,
    re.LastEditedBy
FROM 
    RankedPosts rp
LEFT JOIN 
    TagStatistics ts ON POSITION(ts.TagName IN rp.Tags) > 0
LEFT JOIN 
    RecentEdits re ON rp.PostId = re.PostId
WHERE 
    rp.PostRank <= 5 
ORDER BY 
    rp.OwnerDisplayName, rp.Score DESC;
