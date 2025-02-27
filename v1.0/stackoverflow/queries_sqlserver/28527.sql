
WITH TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore,
        STRING_AGG(DISTINCT U.DisplayName, ', ') AS TopUsers
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' + '<' + T.TagName + '>' + '%'
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(YEAR, 1, 0)
    GROUP BY 
        T.TagName
),
TopTagStats AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagStatistics
)
SELECT 
    T.TagName,
    T.PostCount,
    T.TotalViews,
    T.AverageScore,
    T.TopUsers
FROM 
    TopTagStats T
WHERE 
    T.TagRank <= 10
ORDER BY 
    T.TagRank;
