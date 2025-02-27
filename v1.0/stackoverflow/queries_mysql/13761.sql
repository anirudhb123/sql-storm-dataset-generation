
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COUNT(P.Id) AS TotalPosts,
    AVG(P.ViewCount) AS AverageViewCount,
    AVG(P.Score) AS AverageScore
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
GROUP BY 
    U.Id, U.DisplayName, P.ViewCount, P.Score
ORDER BY 
    TotalPosts DESC;
