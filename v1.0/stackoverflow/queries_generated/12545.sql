-- Performance Benchmarking Query
-- This query retrieves the count of posts, the average score of posts, and the number of users who have made posts 
-- grouped by post types and orders the results by the number of posts in descending order.

SELECT 
    pt.Name AS PostType, 
    COUNT(p.Id) AS TotalPosts, 
    AVG(p.Score) AS AverageScore, 
    COUNT(DISTINCT p.OwnerUserId) AS UniqueUsers
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
