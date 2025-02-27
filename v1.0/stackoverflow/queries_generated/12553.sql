-- Performance Benchmarking Query

-- Measure the number of posts created each month and their average score, 
-- along with the number of unique users who created those posts.

SELECT 
    DATE_TRUNC('month', CreationDate) AS Month,
    COUNT(*) AS TotalPosts,
    AVG(Score) AS AverageScore,
    COUNT(DISTINCT OwnerUserId) AS UniqueUsers
FROM 
    Posts
GROUP BY 
    Month
ORDER BY 
    Month;
