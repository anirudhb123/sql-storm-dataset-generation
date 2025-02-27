-- Performance benchmarking query: Retrieve users with the highest reputation and their posts count, along with average score of their posts.

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    COUNT(P.Id) AS PostsCount,
    AVG(P.Score) AS AveragePostScore
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
GROUP BY 
    U.Id, U.DisplayName, U.Reputation
ORDER BY 
    U.Reputation DESC, PostsCount DESC
LIMIT 100;  -- Limit the results to the top 100 users based on reputation
