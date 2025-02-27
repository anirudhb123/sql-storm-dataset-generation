WITH TagStats AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(COALESCE(P.Score, 0)) AS AverageScore,
        STRING_AGG(DISTINCT U.DisplayName, ', ') AS TopContributors
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        T.Id, T.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        AverageScore,
        TopContributors,
        DENSE_RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagStats
)
SELECT 
    TagName,
    PostCount,
    TotalViews,
    AverageScore,
    TopContributors
FROM 
    TopTags
WHERE 
    TagRank <= 10
ORDER BY 
    TagRank;

This SQL query benchmarks string processing by analyzing tag usage on posts, aggregating relevant statistics such as the number of posts, total views, average score, and top contributors for each tag. It employs common table expressions (CTEs) for structured data processing and filtering, showcasing advanced SQL capabilities. The final result presents the top 10 tags based on their post count, reflecting their importance and engagement within the community.
