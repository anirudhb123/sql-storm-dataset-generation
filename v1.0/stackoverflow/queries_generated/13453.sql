-- Performance Benchmarking Query

-- Retrieve the total number of posts, the average score of posts, 
-- and the count of distinct users who have posted in the last year.

SELECT 
    COUNT(P.Id) AS TotalPosts,
    AVG(P.Score) AS AverageScore,
    COUNT(DISTINCT P.OwnerUserId) AS DistinctUsers
FROM 
    Posts P
WHERE 
    P.CreationDate >= NOW() - INTERVAL '1 year';
