
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
), 
TagCounts AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts,
        LATERAL FLATTEN(input => string_split(substring(Tags, 2, len(Tags) - 2), '><')) 
    WHERE 
        PostTypeId = 1
    GROUP BY 
        value
), 
TopTags AS (
    SELECT 
        TagName,
        TagCount,
        RANK() OVER (ORDER BY TagCount DESC) AS TagRank
    FROM 
        TagCounts
    WHERE 
        TagCount > 5 
), 
PostHistories AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate,
        ph.UserDisplayName,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    tt.TagName,
    rp.OwnerDisplayName,
    rp.Reputation,
    ph.UserDisplayName AS Editor,
    ph.Comment AS EditComment,
    ph.HistoryDate
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistories ph ON rp.PostId = ph.PostId AND ph.HistoryRank = 1  
JOIN 
    (SELECT * FROM TopTags LIMIT 10) tt ON POSITION(tt.TagName IN rp.Tags) > 0  
WHERE 
    rp.PostRank = 1  
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
