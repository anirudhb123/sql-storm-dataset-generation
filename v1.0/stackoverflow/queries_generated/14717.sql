-- Performance Benchmarking Query for Stack Overflow Schema

-- This query retrieves the total number of posts, average score of questions, 
-- total number of users, and average reputation of users who have authored more than 5 posts.
WITH PostStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        AVG(Score) AS AverageQuestionScore
    FROM Posts
    WHERE PostTypeId = 1 -- Only count questions
),
UserStats AS (
    SELECT 
        COUNT(DISTINCT Id) AS TotalUsers,
        AVG(Reputation) AS AverageReputation
    FROM Users
    WHERE Id IN (SELECT OwnerUserId FROM Posts GROUP BY OwnerUserId HAVING COUNT(*) > 5)
)
SELECT 
    PS.TotalPosts,
    PS.AverageQuestionScore,
    US.TotalUsers,
    US.AverageReputation
FROM PostStats PS, UserStats US;
