
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
        SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore,
        SUM(CASE WHEN p.AnswerCount IS NOT NULL THEN p.AnswerCount ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.CommentCount IS NOT NULL THEN p.CommentCount ELSE 0 END) AS TotalComments
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
        TotalAnswers,
        TotalComments,
        @rownum := @rownum + 1 AS Rank
    FROM 
        UserPostStats, (SELECT @rownum := 0) r
    ORDER BY 
        TotalScore DESC
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    Questions,
    Answers,
    TotalViews,
    TotalScore,
    TotalAnswers,
    TotalComments
FROM 
    TopUsers
WHERE 
    Rank <= 10;
