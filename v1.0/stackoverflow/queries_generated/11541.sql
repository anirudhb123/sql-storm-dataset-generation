-- Performance benchmarking query for the Stack Overflow schema

-- This query retrieves the number of posts per user along with their average score, 
-- total view count, and the number of posts created, for performance analysis.

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COUNT(P.Id) AS TotalPosts,
    AVG(P.Score) AS AverageScore,
    SUM(P.ViewCount) AS TotalViewCount
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
GROUP BY 
    U.Id, U.DisplayName
ORDER BY 
    TotalPosts DESC
LIMIT 100;
