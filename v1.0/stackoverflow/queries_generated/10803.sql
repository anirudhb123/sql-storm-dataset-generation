-- Performance Benchmarking Query

-- This query will return the count of posts, average score of questions, and the number of users active in the last week
-- It uses JOINs across multiple tables to evaluate performance in retrieval across the schema

WITH RecentUsers AS (
    SELECT Id
    FROM Users
    WHERE LastAccessDate >= NOW() - INTERVAL '7 days'
),
QuestionStats AS (
    SELECT 
        COUNT(*) AS TotalQuestions,
        AVG(Score) AS AverageScore
    FROM Posts
    WHERE PostTypeId = 1 -- Only questions
)

SELECT 
    (SELECT TotalQuestions FROM QuestionStats) AS TotalQuestions,
    (SELECT AverageScore FROM QuestionStats) AS AverageScore,
    (SELECT COUNT(*) FROM RecentUsers) AS ActiveUsers
FROM 
    DUAL;  -- Use DUAL if supported, otherwise just use SELECT without a FROM clause
