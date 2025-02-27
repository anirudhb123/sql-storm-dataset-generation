WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY substring(Tags, 2, length(Tags)-2) ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Filtering for Questions only
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
),
TagCounts AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount
    FROM 
        PopularTags
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
    LIMIT 10  -- Get top 10 most popular tags
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Tags,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    tc.Tag AS PopularTag,
    tc.TagCount
FROM 
    RankedPosts rp
JOIN 
    TagCounts tc ON rp.Tags ILIKE '%' || tc.Tag || '%'
WHERE 
    rp.Rank <= 5  -- Only select top 5 ranked posts per tag
ORDER BY 
    tc.TagCount DESC, rp.Score DESC;
