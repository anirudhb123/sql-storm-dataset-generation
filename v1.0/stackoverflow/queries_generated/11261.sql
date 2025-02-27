-- Performance benchmarking query to retrieve top users with the highest reputation,
-- number of posts created, and average score of their posts.

SELECT 
    U.Id AS UserId,
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
    U.Reputation DESC, 
    PostCount DESC, 
    AveragePostScore DESC
LIMIT 10;
