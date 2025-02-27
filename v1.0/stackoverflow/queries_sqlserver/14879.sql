
SELECT 
    COUNT(P.Id) AS TotalPosts,
    AVG(P.ViewCount) AS AverageViewCount,
    COUNT(C.Id) AS TotalComments
FROM 
    Posts P
LEFT JOIN 
    Comments C ON P.Id = C.PostId
WHERE 
    P.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(YEAR, 1, 0)
GROUP BY 
    P.Id, P.ViewCount;
