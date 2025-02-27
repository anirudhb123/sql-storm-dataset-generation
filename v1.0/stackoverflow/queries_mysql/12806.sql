
WITH UserPostStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews,
        COUNT(C.Id) AS TotalComments
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalPosts, 
        TotalQuestions, 
        TotalAnswers, 
        TotalScore, 
        TotalViews, 
        TotalComments,
        @ScoreRank := IF(@prevScore = TotalScore, @ScoreRank, @rank) AS ScoreRank,
        @prevScore := TotalScore,
        @ViewsRank := IF(@prevViews = TotalViews, @ViewsRank, @rankViews) AS ViewsRank,
        @prevViews := TotalViews
    FROM UserPostStatistics, (SELECT @ScoreRank := 0, @ViewsRank := 0, @prevScore := NULL, @prevViews := NULL) AS vars
    ORDER BY TotalScore DESC, TotalViews DESC
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalScore,
    TotalViews,
    TotalComments,
    ScoreRank,
    ViewsRank
FROM TopUsers
WHERE ScoreRank <= 10 OR ViewsRank <= 10
ORDER BY ScoreRank, ViewsRank;
