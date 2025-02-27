-- Performance Benchmarking SQL Query

-- This query retrieves the count of posts, average score, and average view count
-- grouped by post type with a limit on the number of returned rows for performance testing

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC
LIMIT 100; -- Limit the number of rows to improve performance benchmarking
