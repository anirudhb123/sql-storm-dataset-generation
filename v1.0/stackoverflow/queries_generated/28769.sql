WITH TagStats AS (
    SELECT 
        T.Id AS TagId,
        T.TagName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.Id, T.TagName
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAnswered,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersProvided,
        SUM(COALESCE(CM.Score, 0)) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments CM ON CM.UserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName
),
RankedUsers AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.TotalPosts,
        U.QuestionsAnswered,
        U.AnswersProvided,
        U.TotalComments,
        RANK() OVER (ORDER BY U.TotalComments DESC) AS CommentRank
    FROM 
        UserStats U
),
FilteredTags AS (
    SELECT 
        T.TagId,
        T.TagName,
        T.TotalPosts,
        T.TotalQuestions,
        T.TotalAnswers,
        T.TotalViews,
        R.CommentRank
    FROM 
        TagStats T
    LEFT JOIN 
        RankedUsers R ON R.TotalPosts > 0
    WHERE 
        T.TotalPosts > 10 AND T.TotalViews > 1000
)
SELECT 
    FT.TagId,
    FT.TagName,
    FT.TotalPosts,
    FT.TotalQuestions,
    FT.TotalAnswers,
    FT.TotalViews,
    FT.CommentRank
FROM 
    FilteredTags FT
ORDER BY 
    FT.TotalViews DESC, FT.TagName;
