WITH TagCounts AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only questions
    GROUP BY 
        TagName
),
TagDetails AS (
    SELECT 
        Tags.TagName,
        Tags.Count AS TotalTagCount,
        COALESCE(tc.PostCount, 0) AS QuestionPostCount,
        (COALESCE(tc.PostCount, 0)::decimal / NULLIF(Tags.Count, 0)) * 100 AS PercentageOfQuestions
    FROM 
        Tags
    LEFT JOIN 
        TagCounts tc ON Tags.TagName = tc.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PercentageOfQuestions,
        ROW_NUMBER() OVER (ORDER BY PercentageOfQuestions DESC) AS Rank
    FROM 
        TagDetails
)
SELECT 
    TagName,
    TotalTagCount,
    QuestionPostCount,
    PercentageOfQuestions
FROM 
    TopTags
WHERE 
    Rank <= 10; -- Get top 10 tags based on the percentage of questions they are associated with
