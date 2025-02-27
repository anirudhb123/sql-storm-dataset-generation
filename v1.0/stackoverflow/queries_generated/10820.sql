-- Performance benchmarking query for the Stack Overflow schema

-- This query retrieves the number of posts, average score, and average view count 
-- grouped by post type, and orders them by the number of posts in descending order.
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS NumberOfPosts,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    NumberOfPosts DESC;
