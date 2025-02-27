-- Performance Benchmarking Query

-- This query retrieves the count of posts, average score, and total views for each post type
-- to benchmark performance across different post types in the Stack Overflow schema.

SELECT 
    pt.Name AS PostType, 
    COUNT(p.Id) AS PostCount, 
    AVG(p.Score) AS AverageScore, 
    SUM(p.ViewCount) AS TotalViews
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;
