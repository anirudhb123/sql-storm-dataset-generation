-- Performance Benchmarking Query: 
-- This query retrieves the count of posts, average score, and average view count grouped by post type.
-- It also filters for posts created within the last year to improve performance insights.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year' -- Filtering for posts created in the last year
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
