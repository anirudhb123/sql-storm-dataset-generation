
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        STRING_AGG(DISTINCT t.TagName, ',') AS TagsArray
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') AS tag ON 1=1
    LEFT JOIN 
        Tags t ON t.TagName = tag.value
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName, p.ViewCount, p.Score
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    JOIN 
        STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') AS tag ON 1=1
    JOIN 
        Tags t ON t.TagName = tag.value
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        t.TagName
    ORDER BY 
        TagCount DESC
    OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY
),
PostHistoryReports AS (
    SELECT 
        ph.PostId,
        p.Title,
        ph.CreationDate,
        p.OwnerUserId,
        PHType.Name AS ChangeType,
        ph.UserDisplayName,
        ph.Comment,
        ph.Text
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    JOIN 
        PostHistoryTypes PHType ON ph.PostHistoryTypeId = PHType.Id
    WHERE 
        ph.CreationDate >= DATEADD(MONTH, -1, '2024-10-01 12:34:56') 
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.ViewCount,
    rp.Score,
    rp.TagsArray,
    COALESCE(pt.TagCount, 0) AS PopularTagCount,
    phr.UserDisplayName AS LastEditedBy,
    phr.ChangeType,
    phr.Comment AS ChangeComment,
    phr.CreationDate AS ChangeDate
FROM 
    RankedPosts rp
LEFT JOIN 
    PopularTags pt ON rp.TagsArray LIKE '%' + pt.TagName + '%'
LEFT JOIN 
    PostHistoryReports phr ON rp.PostId = phr.PostId
WHERE 
    rp.PostRank <= 3 
ORDER BY 
    rp.OwnerDisplayName, 
    rp.Score DESC;
