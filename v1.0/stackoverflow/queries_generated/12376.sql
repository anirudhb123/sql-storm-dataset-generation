-- Performance Benchmarking SQL Query
-- This query retrieves the count of posts, the average score of those posts, and the average view count,
-- grouped by the post type, while also limiting the results to the top 10 post types by total count.

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
    TotalPosts DESC
LIMIT 10;
