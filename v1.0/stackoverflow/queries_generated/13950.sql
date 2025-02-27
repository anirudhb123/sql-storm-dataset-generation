-- Performance benchmarking query for StackOverflow schema
-- This query retrieves the number of posts, average score, and average view count for each post type

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
