WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS Owner,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.TagName ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND  -- Filtering for questions only
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Posts created in the last year
), 

TagAggregates AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName,
        COUNT(*) AS QuestionCount,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        TagName
),

TopTags AS (
    SELECT 
        TagName,
        QuestionCount,
        AcceptedCount,
        RANK() OVER (ORDER BY QuestionCount DESC) AS Rank
    FROM 
        TagAggregates
)

SELECT 
    tp.TagName,
    tp.QuestionCount,
    tp.AcceptedCount,
    rp.Title AS TopQuestionTitle,
    rp.Owner AS TopQuestionOwner,
    rp.ViewCount AS TopQuestionViews,
    rp.CreationDate AS TopQuestionDate
FROM 
    TopTags tp
LEFT JOIN 
    RankedPosts rp ON tp.TagName = ANY (string_to_array(substring(rp.Tags, 2, length(rp.Tags)-2), '><'))
WHERE 
    tp.Rank <= 10  -- Get top 10 tags
AND 
    rp.TagRank = 1  -- Get top question for each tag
ORDER BY 
    tp.Rank;

This SQL query benchmarks string processing by aggregating and ranking questions based on their associated tags. It collects the top 10 tags with the highest number of questions, and for each of these tags, it retrieves the most viewed question from the last year that belongs to that tag.
