
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
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
        TotalQuestions,
        TotalAnswers,
        TotalScore,
        TotalViews,
        @ScoreRank := IF(@prevScore = TotalScore, @ScoreRank, @rowNum) AS ScoreRank,
        @postsRank := IF(@prevPosts = TotalPosts, @postsRank, @rowNum) AS PostsRank,
        @prevScore := TotalScore,
        @prevPosts := TotalPosts,
        @rowNum := @rowNum + 1
    FROM 
        UserPostStats, (SELECT @ScoreRank := 0, @postsRank := 0, @prevScore := NULL, @prevPosts := NULL, @rowNum := 1) AS vars
    ORDER BY 
        TotalScore DESC, TotalPosts DESC
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalScore,
    TotalViews,
    ScoreRank,
    PostsRank
FROM 
    TopUsers
WHERE 
    ScoreRank <= 10 OR PostsRank <= 10
ORDER BY 
    ScoreRank, PostsRank;
