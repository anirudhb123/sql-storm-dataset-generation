
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewsPerPost,
        AVG(P.Score) AS AvgScorePerPost
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalViews,
        TotalScore,
        AvgViewsPerPost,
        AvgScorePerPost,
        @ScoreRank := IF(@prevScore = TotalScore, @ScoreRank, @ScoreRank + 1) AS ScoreRank,
        @prevScore := TotalScore,
        @ViewsRank := IF(@prevViews = TotalViews, @ViewsRank, @ViewsRank + 1) AS ViewsRank,
        @prevViews := TotalViews
    FROM 
        UserPostStats,
        (SELECT @ScoreRank := 0, @prevScore := NULL, @ViewsRank := 0, @prevViews := NULL) AS vars
    ORDER BY 
        TotalScore DESC, TotalViews DESC
)
SELECT 
    UserId, 
    DisplayName, 
    TotalPosts, 
    TotalQuestions, 
    TotalAnswers, 
    TotalViews, 
    TotalScore, 
    AvgViewsPerPost, 
    AvgScorePerPost,
    ScoreRank,
    ViewsRank
FROM 
    TopUsers
ORDER BY 
    ScoreRank, ViewsRank;
