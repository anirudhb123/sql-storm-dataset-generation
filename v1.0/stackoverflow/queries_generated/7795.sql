WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND -- Questions only
        p.Score > 0 -- Ensure only positive scored posts are considered
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
),
TopRankedPosts AS (
    SELECT 
        rp.*, 
        COUNT(p.TagName) AS TagCount
    FROM 
        RankedPosts rp
    JOIN 
        PopularTags p ON rp.Tags ILIKE '%' || p.TagName || '%'
    GROUP BY 
        rp.PostId, rp.Title, rp.Score, rp.CreationDate, rp.OwnerDisplayName
    HAVING 
        COUNT(p.TagName) > 1 -- Only consider posts with multiple popular tags
    ORDER BY 
        rp.Score DESC, TagCount DESC
)
SELECT 
    PostId, 
    Title, 
    Score, 
    CreationDate, 
    OwnerDisplayName
FROM 
    TopRankedPosts
WHERE 
    Rank <= 5; -- Return top 5 posts per tag
