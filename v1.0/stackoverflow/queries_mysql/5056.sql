
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.CommentCount, 0)) AS TotalComments,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        QuestionCount, 
        AnswerCount, 
        TotalScore, 
        TotalViews, 
        TotalComments, 
        TotalBadges,
        @rank := IF(@prev_score = TotalScore AND @prev_views = TotalViews AND @prev_comments = TotalComments, @rank, @rank + 1) AS UserRank,
        @prev_score := TotalScore,
        @prev_views := TotalViews,
        @prev_comments := TotalComments
    FROM 
        UserPostStats, (SELECT @rank := 0, @prev_score := NULL, @prev_views := NULL, @prev_comments := NULL) AS vars
    ORDER BY 
        TotalScore DESC, TotalViews DESC, TotalComments DESC
)
SELECT 
    tu.DisplayName,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.TotalScore,
    tu.TotalViews,
    tu.TotalComments,
    tu.TotalBadges
FROM 
    TopUsers tu
WHERE 
    tu.UserRank <= 10
ORDER BY 
    tu.UserRank;
