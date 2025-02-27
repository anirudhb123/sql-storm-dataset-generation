-- Benchmarking string processing by analyzing the most popular tags, along with user engagement on related posts
WITH PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AvgScore,
        STRING_AGG(DISTINCT U.DisplayName, ', ') AS ActiveUsers
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1  -- Only Questions
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(P.Id) > 10  -- Filter for tags with a significant number of posts
),
TagEngagement AS (
    SELECT 
        PT.TagName,
        PT.PostCount,
        PT.TotalViews,
        PT.AvgScore,
        REGEXP_REPLACE(PT.ActiveUsers, ',\s*', ' AND ') AS UserEngagement
    FROM 
        PopularTags PT
)
SELECT 
    TE.TagName,
    TE.PostCount,
    TE.TotalViews,
    TE.AvgScore,
    'Active users: ' || TE.UserEngagement AS EngagementDetails
FROM 
    TagEngagement TE
ORDER BY 
    TE.TotalViews DESC, TE.AvgScore DESC
LIMIT 10;

This query performs the following tasks:

1. **PopularTags CTE**: It calculates the popularity of tags by counting the associated questions, aggregating total views and average scores, and collecting active user names.

2. **TagEngagement CTE**: Refines results for clarity in user engagement representation by replacing commas with 'AND' for better readability.

3. **Final Selection**: Selects and orders the top popular tags based on total views and average scores while summarizing the engagement details with formatted strings for clarity.

This SQL statement can be used to benchmark string processing and enhance understanding of tag usage in the context of user engagement on a platform.
