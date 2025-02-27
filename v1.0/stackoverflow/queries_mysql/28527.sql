
WITH TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore,
        GROUP_CONCAT(DISTINCT U.DisplayName ORDER BY U.DisplayName SEPARATOR ', ') AS TopUsers
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%<', T.TagName, '>%')
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= '2023-10-01 12:34:56'
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
