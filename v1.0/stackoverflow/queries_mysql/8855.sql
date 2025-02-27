
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(P.Score) AS TotalScore,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT B.Id) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
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
        TotalScore, 
        TotalViews, 
        TotalComments, 
        TotalBadges,
        @ScoreRank := IF(@prevScore = TotalScore, @ScoreRank, @rank) AS ScoreRank,
        @prevScore := TotalScore,
        @rank := @rank + 1
    FROM 
        UserStats, (SELECT @prevScore := NULL, @ScoreRank := 0, @rank := 0) r
    ORDER BY 
        TotalScore DESC
), 
Ranks AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalScore,
        TotalViews,
        TotalComments,
        TotalBadges,
        ScoreRank,
        @ViewsRank := IF(@prevViews = TotalViews, @ViewsRank, @rank) AS ViewsRank,
        @prevViews := TotalViews,
        @rank := @rank + 1
    FROM 
        TopUsers, (SELECT @prevViews := NULL, @ViewsRank := 0, @rank := 0) r
    ORDER BY 
        TotalViews DESC
)
SELECT 
    U.DisplayName,
    U.TotalPosts,
    U.TotalQuestions,
    U.TotalAnswers,
    U.TotalScore,
    U.TotalViews,
    U.TotalComments,
    U.TotalBadges,
    T.ScoreRank,
    T.ViewsRank
FROM 
    UserStats U
JOIN 
    Ranks T ON U.UserId = T.UserId
WHERE 
    T.ScoreRank <= 10 OR T.ViewsRank <= 10
ORDER BY 
    T.ScoreRank, T.ViewsRank;
