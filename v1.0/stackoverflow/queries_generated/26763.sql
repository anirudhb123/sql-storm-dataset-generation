WITH TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        AVG(P.Score) AS AverageScore,
        STRING_AGG(DISTINCT U.DisplayName, ', ') AS ContributorNames
    FROM 
        Tags AS T
    LEFT JOIN 
        Posts AS P ON P.Tags LIKE '%' || T.TagName || '%'
    LEFT JOIN 
        Users AS U ON U.Id = P.OwnerUserId
    WHERE 
        P.PostTypeId = 1 -- Considering only Questions
    GROUP BY 
        T.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        AverageScore,
        ContributorNames,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagStatistics
)
SELECT 
    Rank,
    TagName,
    PostCount,
    TotalViews,
    AverageScore,
    ContributorNames
FROM 
    TopTags
WHERE 
    Rank <= 10
ORDER BY 
    Rank;

This query computes statistics for tags used in questions, including the number of posts, total views, average scores, and a concatenated list of contributor usernames. It filters to only work on the most relevant posts (question type) and ranks the top tags based on the post count. The output includes the rank, tag name, post count, total views, average score, and contributor names.
