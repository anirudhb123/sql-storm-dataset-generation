
WITH TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        AVG(P.Score) AS AverageScore,
        GROUP_CONCAT(DISTINCT U.DisplayName ORDER BY U.DisplayName SEPARATOR ', ') AS ContributorNames
    FROM 
        Tags AS T
    LEFT JOIN 
        Posts AS P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    LEFT JOIN 
        Users AS U ON U.Id = P.OwnerUserId
    WHERE 
        P.PostTypeId = 1 
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
