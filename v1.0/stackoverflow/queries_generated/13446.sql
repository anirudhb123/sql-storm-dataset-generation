-- Performance benchmarking query to evaluate the number of posts, average score, and user reputation for the top 10 users with the most posts
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
    PostCount DESC
LIMIT 10;
