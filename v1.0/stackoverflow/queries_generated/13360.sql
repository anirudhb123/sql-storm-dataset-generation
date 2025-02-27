-- Performance Benchmarking Query
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.AnswerCount, 0)) AS TotalAnswers,
        SUM(COALESCE(P.CommentCount, 0)) AS TotalComments,
        SUM(COALESCE(P.FavoriteCount, 0)) AS TotalFavorites,
        SUM(COALESCE(B.Id IS NOT NULL, 0)) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostHistoryStats AS (
    SELECT 
        PH.UserId,
        COUNT(PH.Id) AS EditCount,
        COUNT(DISTINCT PH.PostId) AS EditedPostCount
    FROM 
        PostHistory PH
    GROUP BY 
        PH.UserId
)
SELECT 
    U.DisplayName,
    UPS.PostCount,
    UPS.TotalScore,
    UPS.TotalViews,
    UPS.TotalAnswers,
    UPS.TotalComments,
    UPS.TotalFavorites,
    UPS.BadgeCount,
    PHS.EditCount,
    PHS.EditedPostCount
FROM 
    UserPostStats UPS
LEFT JOIN 
    PostHistoryStats PHS ON UPS.UserId = PHS.UserId
ORDER BY 
    UPS.TotalScore DESC;
