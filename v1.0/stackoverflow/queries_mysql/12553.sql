
SELECT 
    DATE_FORMAT(CreationDate, '%Y-%m-01') AS Month,
    COUNT(*) AS TotalPosts,
    AVG(Score) AS AverageScore,
    COUNT(DISTINCT OwnerUserId) AS UniqueUsers
FROM 
    Posts
GROUP BY 
    Month, CreationDate, Score, OwnerUserId
ORDER BY 
    Month;
