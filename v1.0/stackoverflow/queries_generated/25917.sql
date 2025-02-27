WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Tags,
        p.AnswerCount,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
AggregatedTags AS (
    SELECT 
        TRIM(UNNEST(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><'))) ) AS TagName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        TRIM(UNNEST(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')))
),
TopTags AS (
    SELECT 
        TagName,
        QuestionCount,
        TotalViews,
        RANK() OVER (ORDER BY TotalViews DESC) AS Rank
    FROM 
        AggregatedTags
)
SELECT 
    t.TagName,
    t.QuestionCount,
    t.TotalViews,
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate
FROM 
    TopTags t
JOIN 
    RankedPosts rp ON t.TagName = TRIM(UNNEST(string_to_array(SUBSTRING(rp.Tags, 2, LENGTH(rp.Tags) - 2), '><')))
WHERE 
    t.Rank <= 10
ORDER BY 
    t.Rank, rp.CreationDate DESC;
