
SELECT 
    COUNT(DISTINCT P.Id) AS TotalPosts,
    AVG(P.Score) AS AveragePostScore,
    AVG(P.ViewCount) AS AverageViewCount,
    COUNT(DISTINCT U.Id) AS TotalUsers
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.CreationDate >= DATE_SUB(CAST('2024-10-01' AS DATE), INTERVAL 1 YEAR)
GROUP BY 
    P.OwnerUserId, P.Score, P.ViewCount;
