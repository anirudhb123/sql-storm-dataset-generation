WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
        AND p.Score > 0
),
TagStats AS (
    SELECT 
        TRIM(UNNEST(string_to_array(p.Tags, '><'))) AS Tag,
        COUNT(*) AS TagCount,
        AVG(p.Score) AS AvgScore
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        TagCount,
        AvgScore,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS Rank
    FROM 
        TagStats
    WHERE 
        TagCount > 10 -- Only consider tags with more than 10 questions
),
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.Score,
        rp.ViewCount,
        tt.Tag
    FROM 
        RankedPosts rp
    JOIN 
        TopTags tt ON rp.Tags LIKE '%' || tt.Tag || '%'
    WHERE 
        rp.RankByViews <= 5 -- Limit to top 5 posts per tag
)
SELECT 
    trp.Title,
    trp.OwnerDisplayName,
    trp.Score,
    trp.ViewCount,
    tt.Tag
FROM 
    TopRankedPosts trp
JOIN 
    TopTags tt ON trp.Tag = tt.Tag
ORDER BY 
    tt.Tag, trp.ViewCount DESC;
