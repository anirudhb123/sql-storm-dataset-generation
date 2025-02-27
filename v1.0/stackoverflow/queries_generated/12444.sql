-- Performance benchmarking query for Stack Overflow schema

WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        COUNT(a.Id) FILTER (WHERE p.PostTypeId = 2) AS TotalAnswers,  -- Count Answers
        COUNT(q.Id) FILTER (WHERE p.PostTypeId = 1) AS TotalQuestions,  -- Count Questions
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViewCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Posts a ON p.Id = a.ParentId  -- To count answers linked to questions
    LEFT JOIN Posts q ON p.AcceptedAnswerId = q.Id  -- To count accepted answers for questions
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalAnswers,
        TotalQuestions,
        TotalScore,
        AvgViewCount,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM UserPostStats
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalAnswers,
    TotalQuestions,
    TotalScore,
    AvgViewCount,
    PostRank,
    ScoreRank
FROM TopUsers
WHERE PostRank <= 10 OR ScoreRank <= 10
ORDER BY PostRank, ScoreRank;
