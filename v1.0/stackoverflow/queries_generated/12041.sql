-- Performance Benchmarking Query
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore,
        AVG(P.CreationDate) AS AvgPostCreationDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostHistoryStats AS (
    SELECT 
        PH.UserId,
        COUNT(PH.Id) AS TotalHistoryEntries,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS TotalPostClosed,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 24 THEN 1 END) AS TotalEditSuggested,
        AVG(PH.CreationDate) AS AvgHistoryCreationDate
    FROM 
        PostHistory PH
    GROUP BY 
        PH.UserId
)
SELECT 
    UPS.UserId,
    UPS.DisplayName,
    UPS.TotalPosts,
    UPS.TotalQuestions,
    UPS.TotalAnswers,
    UPS.TotalViews,
    UPS.TotalScore,
    UPS.AvgPostCreationDate,
    PHS.TotalHistoryEntries,
    PHS.TotalPostClosed,
    PHS.TotalEditSuggested,
    PHS.AvgHistoryCreationDate
FROM 
    UserPostStats UPS
LEFT JOIN 
    PostHistoryStats PHS ON UPS.UserId = PHS.UserId
ORDER BY 
    UPS.TotalScore DESC;
