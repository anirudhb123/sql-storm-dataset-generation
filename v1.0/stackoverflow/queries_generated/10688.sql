-- Performance Benchmarking Query

-- This query retrieves various statistics about posts created by users,
-- including the number of posts, average score, and average view count,
-- grouped by their user reputation and sorted by post count.

SELECT 
    U.Reputation,
    COUNT(P.Id) AS TotalPosts,
    AVG(P.Score) AS AverageScore,
    AVG(P.ViewCount) AS AverageViewCount
FROM 
    Users U
JOIN 
    Posts P ON U.Id = P.OwnerUserId
GROUP BY 
    U.Reputation
ORDER BY 
    TotalPosts DESC;
