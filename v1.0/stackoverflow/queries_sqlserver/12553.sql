
SELECT 
    DATEADD(month, DATEDIFF(month, 0, CreationDate), 0) AS Month,
    COUNT(*) AS TotalPosts,
    AVG(Score) AS AverageScore,
    COUNT(DISTINCT OwnerUserId) AS UniqueUsers
FROM 
    Posts
GROUP BY 
    DATEADD(month, DATEDIFF(month, 0, CreationDate), 0)
ORDER BY 
    Month;
