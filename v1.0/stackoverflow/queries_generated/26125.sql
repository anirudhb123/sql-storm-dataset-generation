WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS Author,
        p.CreationDate,
        p.Score,
        RANK() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Only questions
        AND p.Score > 0   -- Only questions with positive scores
),
TopTags AS (
    SELECT 
        unnest(string_to_array(Tags, '><')) AS Tag
    FROM 
        RankedPosts
),
TagPopularity AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount
    FROM 
        TopTags
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
    LIMIT 10  -- Get the top 10 tags
),
PostsWithPopularTags AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Author,
        rp.CreationDate,
        rp.Score,
        tt.Tag
    FROM 
        RankedPosts rp
    JOIN 
        TopTags tt ON tt.Tag = ANY(string_to_array(rp.Tags, '><')) 
    WHERE 
        rp.PostId IN (SELECT PostId FROM RankedPosts WHERE PostRank = 1)  -- Only include top-ranked posts per tag
)
SELECT 
    p.PostId,
    p.Title,
    p.Body,
    p.Author,
    p.CreationDate,
    p.Score,
    STRING_AGG(pt.Tag, ', ') AS PopularTags
FROM 
    PostsWithPopularTags p
JOIN 
    TagPopularity pt ON pt.Tag = p.Tag
GROUP BY 
    p.PostId, p.Title, p.Body, p.Author, p.CreationDate, p.Score
ORDER BY 
    p.Score DESC, p.CreationDate DESC;
