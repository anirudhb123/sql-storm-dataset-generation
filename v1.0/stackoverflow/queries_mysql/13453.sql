
SELECT 
    COUNT(P.Id) AS TotalPosts,
    AVG(P.Score) AS AverageScore,
    COUNT(DISTINCT P.OwnerUserId) AS DistinctUsers
FROM 
    Posts P
WHERE 
    P.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR;
