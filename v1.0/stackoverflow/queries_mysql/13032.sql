
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        COALESCE(SUM(p.AnswerCount), 0) AS TotalAnswers,
        COALESCE(SUM(p.CommentCount), 0) AS TotalComments
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
        PostCount,
        TotalScore,
        TotalViews,
        TotalAnswers,
        TotalComments,
        @rank_score := IF(@prev_score = TotalScore, @rank_score, @rank_score + 1) AS RankByScore,
        @prev_score := TotalScore,
        @rank_views := IF(@prev_views = TotalViews, @rank_views, @rank_views + 1) AS RankByViews,
        @prev_views := TotalViews
    FROM 
        UserPostStats, 
        (SELECT @rank_score := 0, @prev_score := NULL, @rank_views := 0, @prev_views := NULL) r
    ORDER BY 
        TotalScore DESC, TotalViews DESC
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    TotalScore,
    TotalViews,
    TotalAnswers,
    TotalComments,
    RankByScore,
    RankByViews
FROM 
    TopUsers
WHERE 
    RankByScore <= 10 OR RankByViews <= 10
ORDER BY 
    RankByScore, RankByViews;
