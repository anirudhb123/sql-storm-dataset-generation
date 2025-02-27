
WITH TagStats AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(IFNULL(P.ViewCount, 0)) AS TotalViews,
        SUM(IFNULL(P.AnswerCount, 0)) AS TotalAnswers,
        SUM(IFNULL(P.CommentCount, 0)) AS TotalComments
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.TagName
),
TopTags AS (
    SELECT 
        TagName,
        TotalViews,
        @row_num := @row_num + 1 AS RN
    FROM 
        TagStats, (SELECT @row_num := 0) AS rn
    ORDER BY 
        TotalViews DESC
)
SELECT 
    T.TagName,
    T.TotalViews,
    P.Title AS MostViewedPost,
    P.ViewCount AS PostViewCount
FROM 
    TopTags T
JOIN 
    Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
WHERE 
    T.RN <= 10 
ORDER BY 
    T.TotalViews DESC;
