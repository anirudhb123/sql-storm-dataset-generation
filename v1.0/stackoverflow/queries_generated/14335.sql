-- Performance Benchmarking SQL Query
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativeScorePosts
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
TagStats AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AvgScore
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
),
CommentStats AS (
    SELECT 
        P.Id AS PostId,
        COUNT(C.Id) AS CommentCount,
        MAX(C.CreationDate) AS LastCommentDate
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.TotalPosts,
    US.TotalQuestions,
    US.TotalAnswers,
    US.PositiveScorePosts,
    US.NegativeScorePosts,
    TS.TagName,
    TS.PostCount,
    TS.TotalViews,
    TS.AvgScore,
    CS.CommentCount,
    CS.LastCommentDate
FROM 
    UserStats US
LEFT JOIN 
    TagStats TS ON TS.PostCount > 0
LEFT JOIN 
    CommentStats CS ON US.TotalPosts > 0
ORDER BY 
    US.TotalPosts DESC, US.DisplayName;
