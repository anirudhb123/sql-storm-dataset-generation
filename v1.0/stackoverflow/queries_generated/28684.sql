WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS ViewRank,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.AnswerCount DESC) AS AnswerRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only questions
        AND p.CreationDate BETWEEN '2022-01-01' AND '2023-10-31'  -- Filtered by recent year
),
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.AnswerCount,
        CASE 
            WHEN rp.ViewRank = 1 THEN 'Most Viewed'
            WHEN rp.AnswerRank = 1 THEN 'Most Answered'
            ELSE 'Regular'
        END AS PostCategory
    FROM 
        RankedPosts rp
),
TopTags AS (
    SELECT 
        TRIM(UNNEST(string_to_array(p.Tags, '>')) ) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
    LIMIT 5  -- Top 5 tags
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.AnswerCount,
    ps.PostCategory,
    tt.Tag AS TopTag
FROM 
    PostStats ps
JOIN 
    TopTags tt ON ps.Body LIKE '%' || tt.Tag || '%'
ORDER BY 
    ps.ViewCount DESC,
    ps.AnswerCount DESC;

This query benchmarks string processing within the Stack Overflow schema by retrieving data about recent questions, categorizing them as most viewed or most answered, and filtering for questions that include specific "top tags" in their body text. This enables a comprehensive view of high-engagement posts in relation to popular subjects on the platform.
