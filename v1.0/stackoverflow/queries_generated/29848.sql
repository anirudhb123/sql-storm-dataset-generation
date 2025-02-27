WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        p.CreationDate,
        p.AnswerCount,
        p.ViewCount,
        pt.Name AS PostType,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '6 months' -- Only consider recent posts
      AND 
        p.PostTypeId = 1  -- Only Questions
),
FrequentTags AS (
    SELECT 
        TRIM(UNNEST(string_to_array(p.Tags, '> <'))) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) > 5  -- Only tags with more than 5 posts
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.OwnerDisplayName,
        rp.OwnerReputation,
        rp.CreationDate,
        rp.AnswerCount,
        rp.ViewCount,
        rp.PostType
    FROM 
        RankedPosts rp
    JOIN 
        FrequentTags ft ON rp.Tags ILIKE '%' || ft.Tag || '%' -- Filter posts that contain frequent tags
    WHERE 
        rp.RankByViews <= 10  -- Top 10 posts by views for each tag
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.OwnerDisplayName,
    fp.OwnerReputation,
    fp.CreationDate,
    fp.AnswerCount,
    fp.ViewCount,
    fp.PostType
FROM 
    FilteredPosts fp
ORDER BY 
    fp.ViewCount DESC;
