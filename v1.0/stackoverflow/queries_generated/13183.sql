-- Performance benchmarking query for Stack Overflow schema

-- This query retrieves the number of posts, average score, and total view count 
-- grouped by post type, providing insights into the performance of different post categories.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViewCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    p.CreationDate >= DATEADD(year, -1, GETDATE())  -- Considering posts from the last year
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
