-- Performance Benchmarking Query

WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        SUM(P.Score) AS TotalScore,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViewCount,
        SUM(COALESCE(P.CommentCount, 0)) AS TotalCommentCount,
        SUM(COALESCE(P.FavoriteCount, 0)) AS TotalFavoriteCount
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
        SUM(P.ViewCount) AS TotalViewCount
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON T.Id IN (SELECT unnest(string_to_array(P.Tags, '><'))::int)  -- Assuming Tags are stored as '<tag1><tag2>'
    GROUP BY 
        T.TagName
)

SELECT 
    UPS.UserId,
    UPS.DisplayName,
    UPS.TotalPosts,
    UPS.TotalQuestions,
    UPS.TotalAnswers,
    UPS.TotalScore,
    UPS.TotalViewCount,
    UPS.TotalCommentCount,
    UPS.TotalFavoriteCount,
    TS.TagName,
    TS.PostCount AS RelatedPostCount,
    TS.TotalViewCount AS RelatedTagViewCount
FROM 
    UserPostStats UPS
LEFT JOIN 
    TagStats TS ON UPS.TotalPosts > 0  -- Joining to include any user with posts related to tags
ORDER BY 
    UPS.TotalScore DESC;
