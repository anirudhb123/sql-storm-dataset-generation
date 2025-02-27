-- Performance benchmarking query to retrieve the top 10 users 
-- with the highest reputation and their respective number of posts,
-- along with the average score of their posts.

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    COUNT(P.Id) AS NumberOfPosts,
    AVG(P.Score) AS AveragePostScore
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
GROUP BY 
    U.Id
ORDER BY 
    U.Reputation DESC
LIMIT 10;
