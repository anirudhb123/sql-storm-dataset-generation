-- Performance benchmarking query for Stack Overflow schema
-- This query retrieves the count of posts per post type and the average score of posts
-- The goal is to evaluate query performance against various aggregations
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;
