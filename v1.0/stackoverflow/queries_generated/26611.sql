WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS Author,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Focus on Questions
        AND p.CreationDate > CURRENT_DATE - INTERVAL '1 year'  -- Last year
),
TagAnalysis AS (
    SELECT 
        TRIM(UNNEST(string_to_array(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><'))) ) AS TagName,
        COUNT(*) AS QuestionCount,
        AVG(ViewCount) AS AvgViewCount,
        SUM(AnswerCount) AS TotalAnswers
    FROM 
        RankedPosts
    WHERE 
        TagRank <= 5  -- Top 5 posts per tag
    GROUP BY 
        TagName
),
TagGrowth AS (
    SELECT 
        TagName,
        QuestionCount,
        AvgViewCount,
        TotalAnswers,
        LAG(QuestionCount) OVER (ORDER BY QuestionCount DESC) AS PreviousQuestionCount
    FROM 
        TagAnalysis
)
SELECT 
    TagName,
    QuestionCount,
    AvgViewCount,
    TotalAnswers,
    CASE 
        WHEN PreviousQuestionCount IS NULL THEN 'New Tag'
        WHEN PreviousQuestionCount < QuestionCount THEN 'Increased'
        WHEN PreviousQuestionCount > QuestionCount THEN 'Decreased'
        ELSE 'Stable'
    END AS GrowthStatus
FROM 
    TagGrowth
ORDER BY 
    AvgViewCount DESC, 
    QuestionCount DESC;
