-- Performance Benchmarking Query Example
-- This query retrieves the number of posts, average score, and the total number of users who created those posts
-- Grouped by post type and ordered by number of posts in descending order

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    COUNT(DISTINCT p.OwnerUserId) AS TotalUniqueUsers
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
