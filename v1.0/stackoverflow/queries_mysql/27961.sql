
WITH TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        AVG(COALESCE(P.Score, 0)) AS AverageScore,
        GROUP_CONCAT(DISTINCT U.DisplayName ORDER BY U.DisplayName SEPARATOR ', ') AS TopUsers,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    WHERE 
        T.Count > 0
    GROUP BY 
        T.TagName
),
PopularTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        AverageScore,
        TopUsers,
        CommentCount,
        @rownum := @rownum + 1 AS Rank
    FROM 
        TagStatistics, (SELECT @rownum := 0) r
    ORDER BY 
        PostCount DESC, TotalViews DESC
)

SELECT 
    PT.TagName,
    PT.PostCount,
    PT.TotalViews,
    PT.AverageScore,
    PT.TopUsers,
    PT.CommentCount
FROM 
    PopularTags PT
WHERE 
    PT.Rank <= 10
ORDER BY 
    PT.AverageScore DESC, PT.TotalViews DESC;
