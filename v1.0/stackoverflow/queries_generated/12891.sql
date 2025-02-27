-- Performance Benchmarking Query
-- This query retrieves the total number of posts, average score, and the most recent post for each user in the Users table.

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COUNT(P.Id) AS TotalPosts,
    AVG(P.Score) AS AverageScore,
    MAX(P.CreationDate) AS MostRecentPostDate
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
GROUP BY 
    U.Id, U.DisplayName
ORDER BY 
    TotalPosts DESC;
