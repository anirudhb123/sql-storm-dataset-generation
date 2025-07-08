
WITH RECURSIVE UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
), 
PopularTags AS (
    SELECT 
        TRIM(REGEXP_SUBSTR(A.Tags, '([^><]+)', 1, seq)) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts A,
        TABLE(GENERATOR(ROWCOUNT => (SELECT MAX(LENGTH(A.Tags) - LENGTH(REPLACE(A.Tags, '>', '')) + 1)
                                      FROM Posts A))) AS seq -- Generate sequence
    WHERE 
        A.PostTypeId = 1  
        AND REGEXP_SUBSTR(A.Tags, '([^><]+)', 1, seq) IS NOT NULL
    GROUP BY 
        TRIM(REGEXP_SUBSTR(A.Tags, '([^><]+)', 1, seq))
    HAVING 
        COUNT(*) > 5  
), 
TagStats AS (
    SELECT 
        T.TagName,
        AVG(P.Score) AS AvgScore,
        SUM(P.ViewCount) AS TotalViews,
        COUNT(DISTINCT P.Id) AS QuestionCount
    FROM 
        PopularTags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
)

SELECT 
    UA.DisplayName,
    UA.TotalPosts,
    UA.QuestionCount,
    UA.AnswerCount,
    TS.TagName,
    TS.AvgScore,
    TS.TotalViews
FROM 
    UserActivity UA
LEFT JOIN 
    TagStats TS ON UA.QuestionCount > 0 
ORDER BY 
    UA.TotalPosts DESC, TS.TotalViews DESC
LIMIT 10;
