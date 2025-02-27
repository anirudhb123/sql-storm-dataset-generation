
WITH TagStats AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        AVG(P.Score) AS AverageScore,
        SUM(P.ViewCount) AS TotalViews,
        GROUP_CONCAT(DISTINCT P.OwnerDisplayName SEPARATOR ', ') AS Authors
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    WHERE 
        P.PostTypeId = 1  
    GROUP BY 
        T.TagName
), 
TopTags AS (
    SELECT 
        TagName, 
        PostCount,
        AverageScore,
        TotalViews,
        Authors,
        @rownum := @rownum + 1 AS TagRank
    FROM 
        TagStats, (SELECT @rownum := 0) r
    ORDER BY 
        PostCount DESC
) 
SELECT 
    T.TagName,
    T.PostCount,
    T.AverageScore,
    T.TotalViews,
    T.Authors
FROM 
    TopTags T
WHERE 
    T.TagRank <= 10;
