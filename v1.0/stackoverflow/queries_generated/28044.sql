WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND p.PostTypeId = 1  -- Considering only questions
),

AggregatedTags AS (
    SELECT 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
        AND p.PostTypeId = 1
    GROUP BY 
        TagName
),

TopTags AS (
    SELECT 
        TagName,
        TagCount,
        RANK() OVER (ORDER BY TagCount DESC) AS TagRank
    FROM 
        AggregatedTags
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.CreationDate,
    rp.ViewCount,
    rp.OwnerDisplayName,
    tt.TagName,
    tt.TagCount
FROM 
    RankedPosts rp
LEFT JOIN 
    TopTags tt ON rp.Tags LIKE '%<' || tt.TagName || '>%'
WHERE 
    rp.ViewRank <= 5  -- Getting only the top 5 viewed questions
ORDER BY 
    rp.ViewCount DESC, 
    rp.CreationDate DESC;

This query benchmarks string processing by performing multiple operations such as unnesting tags, using string manipulation functions to filter relevant posts, and ranking both posts based on views and tags based on counts, leading to a comprehensive aggregate view of popular questions within the last year.
