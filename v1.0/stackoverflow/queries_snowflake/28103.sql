
WITH TagStats AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(COALESCE(P.Score, 0)) AS AverageScore,
        LISTAGG(DISTINCT U.DisplayName, ', ') WITHIN GROUP (ORDER BY U.DisplayName) AS TopContributors
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        T.TagName
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
