-- Performance Benchmarking Query for Stack Overflow Schema
-- This query measures the performance of certain operations like joins and aggregations

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COUNT(DISTINCT P.Id) AS NumberOfPosts,
    SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS NumberOfQuestions,
    SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS NumberOfAnswers,
    AVG(U.Reputation) AS AverageReputation,
    MAX(P.CreationDate) AS LastPostDate
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
GROUP BY 
    U.Id, U.DisplayName
ORDER BY 
    NumberOfPosts DESC
LIMIT 100;

-- This query retrieves the top 100 users based on their post counts,
-- along with their average reputation and details about their posts.
