WITH TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COUNT(DISTINCT U.Id) AS UniqueUserCount,
        STRING_AGG(DISTINCT U.DisplayName, ', ') AS UsersEngaged
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        T.Id, T.TagName
), 
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        QuestionCount,
        AnswerCount,
        UniqueUserCount,
        UsersEngaged
    FROM 
        TagStatistics
    WHERE 
        PostCount > 10
    ORDER BY 
        PostCount DESC 
    LIMIT 10
), 
UserEngagement AS (
    SELECT 
        U.DisplayName,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionsAsked,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswersProvided,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
    HAVING 
        COUNT(P.Id) > 5
    ORDER BY 
        TotalViews DESC
), 
PostsTagging AS (
    SELECT 
        P.Id AS PostId,
        T.TagName,
        P.Title
    FROM 
        Posts P
    CROSS JOIN 
        Tags T
    WHERE 
        P.Tags LIKE '%' || T.TagName || '%'
)
SELECT 
    T.TagName,
    T.PostCount,
    T.QuestionCount,
    T.AnswerCount,
    T.UniqueUserCount,
    T.UsersEngaged,
    U.DisplayName AS ActiveUser,
    U.QuestionsAsked,
    U.AnswersProvided,
    U.TotalViews,
    U.TotalScore,
    STRING_AGG(DISTINCT PT.Title, '; ') AS RelatedPosts
FROM 
    TopTags T
JOIN 
    UserEngagement U ON T.UsersEngaged LIKE '%' || U.DisplayName || '%'
LEFT JOIN 
    PostsTagging PT ON PT.TagName = T.TagName
GROUP BY 
    T.TagName, T.PostCount, T.QuestionCount, T.AnswerCount, T.UniqueUserCount, T.UsersEngaged, U.DisplayName, U.QuestionsAsked, U.AnswersProvided, U.TotalViews, U.TotalScore
ORDER BY 
    T.PostCount DESC, U.TotalViews DESC;
