WITH TagStats AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        AVG(COALESCE(P.Score, 0)) AS AverageScore,
        STRING_AGG(DISTINCT U.DisplayName, ', ') AS UsersWithPosts
    FROM 
        Tags
    JOIN 
        Posts P ON P.Tags LIKE '%' || Tags.TagName || '%'
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year' 
    GROUP BY 
        Tags.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        AverageScore,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagStats
)
SELECT 
    T.TagName,
    T.PostCount,
    T.TotalViews,
    T.AverageScore,
    T.UsersWithPosts
FROM 
    TopTags T
WHERE 
    T.Rank <= 10 
ORDER BY 
    T.TotalViews DESC;
