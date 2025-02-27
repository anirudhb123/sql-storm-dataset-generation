-- Benchmark performance query: Retrieve the top 10 users by reputation,
-- along with the number of posts they have created and their total score.

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    COUNT(P.Id) AS PostCount,
    SUM(P.Score) AS TotalScore
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
GROUP BY 
    U.Id, U.DisplayName, U.Reputation
ORDER BY 
    U.Reputation DESC
LIMIT 10;
