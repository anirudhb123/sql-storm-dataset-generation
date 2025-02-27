-- Performance Benchmarking Query
-- This query retrieves the number of posts per user, average score of posts, and user reputation,
-- to evaluate the performance and engagement of users on the Stack Overflow platform.

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COUNT(P.Id) AS PostCount,
    AVG(P.Score) AS AveragePostScore,
    U.Reputation
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
GROUP BY 
    U.Id, U.DisplayName, U.Reputation
ORDER BY 
    PostCount DESC, AveragePostScore DESC;
