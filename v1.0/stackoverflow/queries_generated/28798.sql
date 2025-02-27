WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Considering only Questions
),

TagStatistics AS (
    SELECT 
        unnest(string_to_array(p.Tags, '><')) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        Tag
),

PostModifiers AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS ModificationDate,
        ph.UserDisplayName,
        ph.Comment,
        ph.Text AS OldValue,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS ModificationRank
    FROM 
        PostHistory AS ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Title, Body, Tags modification
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Tags,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score,
    ts.Tag,
    ts.TagCount,
    pm.ModificationDate,
    pm.UserDisplayName AS Modifier,
    pm.Comment AS ModificationComment,
    pm.OldValue
FROM 
    RankedPosts rp
LEFT JOIN 
    TagStatistics ts ON ts.Tag = ANY(string_to_array(rp.Tags, '><'))
LEFT JOIN 
    PostModifiers pm ON pm.PostId = rp.PostId AND pm.ModificationRank = 1
WHERE 
    rp.PostRank <= 5 -- Top 5 questions per user
ORDER BY 
    rp.OwnerDisplayName, rp.Score DESC;
