
SELECT 
    COUNT(P.Id) AS TotalPosts,
    AVG(P.Score) AS AverageScore,
    COUNT(DISTINCT P.OwnerUserId) AS DistinctUsers
FROM 
    Posts P
WHERE 
    P.CreationDate >= CAST(DATEADD(year, -1, '2024-10-01 12:34:56') AS datetime);
