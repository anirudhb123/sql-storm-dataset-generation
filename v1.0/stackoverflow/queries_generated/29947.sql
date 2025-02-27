-- This query benchmarks string processing by examining the tags and titles of posts to find correlations
-- between popular tags and their associated titles in the StackOverflow schema.

WITH TagUsage AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        ARRAY_AGG(DISTINCT P.Title) AS RelatedTitles
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    WHERE 
        P.PostTypeId = 1  -- We only consider Questions
    GROUP BY 
        T.TagName
),
PopularTags AS (
    SELECT 
        TagName,
        PostCount,
        RelatedTitles,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS PopularityRank
    FROM 
        TagUsage
    WHERE 
        PostCount > 10  -- Only consider tags used in more than 10 posts
),
TitleWordCount AS (
    SELECT 
        PT.TagName,
        COUNT(DISTINCT TW.Word) AS DistinctWordCount
    FROM 
        PopularTags PT,
        LATERAL unnest(string_to_array(ARRAY_TO_STRING(PT.RelatedTitles, ' '), ' ')) AS TW(Word)
    GROUP BY 
        PT.TagName
)
SELECT 
    PT.TagName,
    PT.PostCount,
    TWC.DistinctWordCount
FROM 
    PopularTags PT
JOIN 
    TitleWordCount TWC ON PT.TagName = TWC.TagName
ORDER BY 
    PT.PopularityRank;

