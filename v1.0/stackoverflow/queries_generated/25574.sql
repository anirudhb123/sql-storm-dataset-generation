WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.Tags,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Filtering for Questions
        AND p.AnswerCount > 0  -- Only Questions with Answers
),
PopularTags AS (
    SELECT 
        tag, 
        COUNT(tag) AS TagCount
    FROM 
        (SELECT unnest(string_to_array(Trim(both '<>' FROM p.Tags), '> <')) AS tag
         FROM Posts p
         WHERE p.PostTypeId = 1) AS Tags
    GROUP BY 
        tag
    ORDER BY 
        TagCount DESC
    LIMIT 10  -- Get the top 10 most popular tags
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Body,
    rp.Tags,
    rp.ViewCount,
    rp.AnswerCount,
    pt.TagCount AS Popularity
FROM 
    RankedPosts rp
JOIN 
    PopularTags pt ON rp.Tags LIKE '%' || pt.tag || '%'
WHERE 
    rp.TagRank <= 5  -- Get the top 5 Questions for each tag
ORDER BY 
    pt.TagCount DESC, rp.ViewCount DESC;
