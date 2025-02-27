WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND -- Only questions
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Questions created in the last year
),

TagStats AS (
    SELECT 
        UNNEST(string_to_array(Tags, '>')) AS TagName, 
        COUNT(*) AS TagUsageCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only questions
    GROUP BY 
        TagName
),

TopTags AS (
    SELECT 
        TagName,
        TagUsageCount,
        RANK() OVER (ORDER BY TagUsageCount DESC) AS TagRank
    FROM 
        TagStats
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    rp.Tags,
    tt.TagName AS MostPopularTag,
    tt.TagUsageCount AS MostPopularTagCount
FROM 
    RankedPosts rp
JOIN 
    TopTags tt ON rp.Tags LIKE '%' || tt.TagName || '%' -- Join on most popular tags
WHERE 
    rp.Rank <= 5 -- Top 5 ranked posts per tag
ORDER BY 
    rp.Tags, rp.Score DESC; -- Order by tags and then score
