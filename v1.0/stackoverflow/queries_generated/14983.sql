-- Performance benchmarking query for users with the highest reputation who have posted questions and answers
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN p.Score ELSE 0 END) AS TotalQuestionScore,
        SUM(CASE WHEN p.PostTypeId = 2 THEN p.Score ELSE 0 END) AS TotalAnswerScore,
        u.Reputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
RankedUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.TotalPosts,
        ua.TotalQuestions,
        ua.TotalAnswers,
        ua.TotalQuestionScore,
        ua.TotalAnswerScore,
        ua.Reputation,
        RANK() OVER (ORDER BY ua.Reputation DESC) AS UserRank
    FROM 
        UserActivity ua
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalQuestionScore,
    TotalAnswerScore,
    Reputation,
    UserRank
FROM 
    RankedUsers
WHERE 
    UserRank <= 10  -- Top 10 users by reputation
ORDER BY 
    UserRank;
