-- Performance Benchmarking Query for StackOverflow Schema

-- This query retrieves the number of posts, average score of posts, and total number of comments per user,
-- which will help in benchmarking the performance of user engagement.

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COUNT(P.Id) AS TotalPosts,
    AVG(P.Score) AS AveragePostScore,
    COUNT(C.Id) AS TotalComments
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Comments C ON P.Id = C.PostId
GROUP BY 
    U.Id, U.DisplayName
ORDER BY 
    TotalPosts DESC;

