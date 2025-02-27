WITH TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.AnswerCount, 0)) AS TotalAnswers,
        SUM(COALESCE(P.FavoriteCount, 0)) AS TotalFavorites,
        AVG(COALESCE(P.Score, 0)) AS AverageScore
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        COUNT(COALESCE(CM.Id, 0)) AS TotalComments,
        COUNT(DISTINCT B.Id) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments CM ON CM.UserId = U.Id
    LEFT JOIN 
        Badges B ON B.UserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName
),
PostHistoryAnalysis AS (
    SELECT 
        PH.PostId,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 END) AS TotalClosures,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (12, 13) THEN 1 END) AS TotalDeletions,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (24) THEN 1 END) AS TotalEdits
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
)
SELECT 
    TS.TagName,
    TS.PostCount,
    TS.TotalViews,
    TS.TotalAnswers,
    TS.TotalFavorites,
    TS.AverageScore,
    UA.DisplayName,
    UA.TotalPosts,
    UA.TotalComments,
    UA.TotalBadges,
    PHA.TotalClosures,
    PHA.TotalDeletions,
    PHA.TotalEdits
FROM 
    TagStatistics TS
JOIN 
    UserActivity UA ON UA.TotalPosts > 0
JOIN 
    PostHistoryAnalysis PHA ON PHA.PostId IN (SELECT P.Id FROM Posts P WHERE P.Tags LIKE '%' || TS.TagName || '%')
ORDER BY 
    TS.TotalViews DESC, 
    UA.TotalPosts DESC
LIMIT 10;
