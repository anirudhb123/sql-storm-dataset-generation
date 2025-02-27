-- Performance Benchmarking SQL Query

-- This query retrieves the number of posts created by each user along with their reputation,
-- the average view count of their posts, and the total score for all their posts.

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    COUNT(P.Id) AS TotalPosts,
    AVG(P.ViewCount) AS AverageViewCount,
    SUM(P.Score) AS TotalScore
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
GROUP BY 
    U.Id, U.DisplayName, U.Reputation
ORDER BY 
    TotalPosts DESC, Reputation DESC;
