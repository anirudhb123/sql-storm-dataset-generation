WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Tags,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS RankByViews,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.AnswerCount DESC) AS RankByAnswers
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only considering Questions
),

MostPopularTags AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS Tag
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.AnswerCount,
    mt.Tag,
    CASE 
        WHEN rp.RankByViews = 1 THEN 'Most Viewed'
        ELSE 'Other'
    END AS ViewRank,
    CASE 
        WHEN rp.RankByAnswers = 1 THEN 'Most Answered'
        ELSE 'Other'
    END AS AnswerRank
FROM 
    RankedPosts rp
JOIN 
    MostPopularTags mt ON rp.Tags LIKE '%' || mt.Tag || '%'
WHERE 
    rp.RankByViews <= 5 AND 
    rp.RankByAnswers <= 5
ORDER BY 
    mt.Tag, rp.ViewCount DESC, rp.AnswerCount DESC;
