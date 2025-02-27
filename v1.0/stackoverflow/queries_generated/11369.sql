-- Performance Benchmark Query

-- This query retrieves the count of posts, average view count, and average score per post type,
-- and joins multiple tables to gather comprehensive statistics. 

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.ViewCount) AS AverageViewCount,
    AVG(p.Score) AS AverageScore
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;
