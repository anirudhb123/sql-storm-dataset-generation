WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(NULLIF(LENGTH(p.Body), 0), 1) AS BodyLength
    FROM 
        Posts p
        JOIN Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Considering only Questions
        AND p.ViewCount > 100 -- Only questions with more than 100 views
),
TagStatistics AS (
    SELECT 
        UNNEST(STRING_TO_ARRAY(SUBSTRING(Tags, 2, LENGTH(Tags)-2), '><')) AS TagName,
        COUNT(*) AS QuestionCount,
        SUM(BodyLength) AS TotalBodyLength,
        AVG(BodyLength) AS AvgBodyLength
    FROM 
        RankedPosts
    WHERE 
        rn = 1
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        QuestionCount,
        TotalBodyLength,
        AvgBodyLength,
        RANK() OVER (ORDER BY QuestionCount DESC) AS TagRank
    FROM 
        TagStatistics
)

SELECT 
    t.TagName,
    t.QuestionCount,
    t.TotalBodyLength,
    t.AvgBodyLength,
    COALESCE(ROUND(t.TotalBodyLength::numeric / NULLIF(t.QuestionCount, 0), 2), 0) AS AvgBodyLengthPerQuestion
FROM 
    TopTags t
WHERE 
    t.TagRank <= 5 -- Restricting output to top 5 tags
ORDER BY 
    t.TagRank;
