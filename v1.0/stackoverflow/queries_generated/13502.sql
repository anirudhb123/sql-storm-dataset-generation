-- Performance Benchmarking Query

-- This query retrieves the number of posts, average view counts, 
-- and the distribution of post types to assess performance across different post categories.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.ViewCount) AS AverageViewCount,
    SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
    SUM(CASE WHEN p.Score <= 0 THEN 1 ELSE 0 END) AS NonPositiveScorePosts
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
