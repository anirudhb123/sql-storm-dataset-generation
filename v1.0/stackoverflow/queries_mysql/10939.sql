
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
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
        @postRank := IF(@prevPosts = TotalPosts, @postRank, @newRank) AS PostRank,
        @prevPosts := TotalPosts,
        @newRank := @newRank + 1 AS ScoreRank
    FROM 
        UserPostStats, 
        (SELECT @postRank := 0, @prevPosts := 0, @newRank := 0) AS vars
    ORDER BY 
        TotalPosts DESC
)
SELECT 
    UserId, 
    DisplayName, 
    TotalPosts, 
    Questions, 
    Answers, 
    TotalViews, 
    TotalScore,
    PostRank,
    ScoreRank
FROM 
    TopUsers
WHERE 
    PostRank <= 10 OR ScoreRank <= 10
ORDER BY 
    PostRank, ScoreRank;
