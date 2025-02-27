-- Performance Benchmarking Query for StackOverflow Schema
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewsPerPost
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    Questions,
    Answers,
    TotalViews,
    TotalScore,
    AvgViewsPerPost
FROM 
    UserPostStats
ORDER BY 
    TotalScore DESC, TotalPosts DESC
LIMIT 100;

-- This query retrieves user statistics including the total number of posts,
-- breakdown of questions and answers, total views and score, and average views per post
-- for the top 100 users based on their total score.
