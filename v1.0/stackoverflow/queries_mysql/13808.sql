
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews
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
        Questions,
        Answers,
        TotalScore,
        TotalViews,
        @row_num_score := @row_num_score + 1 AS ScoreRank,
        @row_num_view := @row_num_view + 1 AS ViewRank
    FROM 
        UserPostStats, (SELECT @row_num_score := 0, @row_num_view := 0) AS init
    ORDER BY 
        TotalScore DESC, TotalViews DESC
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    Questions,
    Answers,
    TotalScore,
    TotalViews,
    ScoreRank,
    ViewRank
FROM 
    TopUsers
WHERE 
    ScoreRank <= 10 OR ViewRank <= 10
ORDER BY 
    ScoreRank, ViewRank;
