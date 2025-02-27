WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS Rnk
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.Body IS NOT NULL
),
FilteredTags AS (
    SELECT 
        UNNEST(string_to_array(Tags, ',')) AS Tag -- Split string into individual tags
    FROM 
        RankedPosts
    WHERE 
        Rnk <= 10 -- Consider only the latest 10 posts per tag
),
TagCounts AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount
    FROM 
        FilteredTags
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        TagCount,
        RANK() OVER (ORDER BY TagCount DESC) AS Rank
    FROM 
        TagCounts
)
SELECT 
    tt.Tag,
    tt.TagCount,
    p.Title,
    p.OwnerDisplayName,
    p.Score,
    p.ViewCount,
    p.CreationDate
FROM 
    TopTags tt
JOIN 
    RankedPosts p ON p.Tags LIKE '%' || tt.Tag || '%'
WHERE 
    tt.Rank <= 5 -- Get top 5 tags
ORDER BY 
    tt.TagCount DESC, p.Score DESC;
