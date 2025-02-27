
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AverageViewsPerPost
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        Questions,
        Answers,
        TotalViews,
        TotalScore,
        AverageViewsPerPost,
        @scoreRank := IF(@prevScore = TotalScore, @scoreRank, @rowNum) AS ScoreRank,
        @prevScore := TotalScore,
        @rowNum := @rowNum + 1 AS ViewRank
    FROM UserPostStats, (SELECT @scoreRank := 0, @prevScore := NULL, @rowNum := 0) AS vars
    ORDER BY TotalScore DESC
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    Questions,
    Answers,
    TotalViews,
    TotalScore,
    AverageViewsPerPost,
    ScoreRank,
    ViewRank
FROM TopUsers
WHERE ScoreRank <= 10 OR ViewRank <= 10
ORDER BY ScoreRank, ViewRank;
