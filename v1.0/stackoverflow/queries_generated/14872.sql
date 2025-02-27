-- Performance Benchmarking Query
-- This query retrieves the count of posts, average score of questions, and user reputation for the top 10 users

WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        COUNT(P.Id) AS PostCount,
        AVG(P.Score) AS AvgScore,
        U.Reputation
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        P.PostTypeId = 1  -- Only considering questions
    GROUP BY 
        U.Id
)

SELECT 
    U.UserId,
    U.PostCount,
    U.AvgScore,
    U.Reputation
FROM 
    UserPostStats U
ORDER BY 
    U.Reputation DESC
LIMIT 10;

-- This query will allow for the analysis of user engagement through post creation and their reputation on the platform.
