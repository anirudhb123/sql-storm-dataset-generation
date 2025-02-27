-- Performance Benchmark Query for StackOverflow Schema

-- This query will measure the performance of joining multiple tables and aggregating data.
-- It retrieves the top 10 users based on their reputation and the number of posts they have made,
-- along with the average score of their posts.

SELECT 
    U.DisplayName,
    U.Reputation,
    COUNT(P.Id) AS PostCount,
    AVG(P.Score) AS AveragePostScore
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
GROUP BY 
    U.Id, U.DisplayName, U.Reputation
ORDER BY 
    U.Reputation DESC, PostCount DESC
LIMIT 10;
