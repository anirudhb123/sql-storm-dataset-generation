-- Performance benchmarking query for Stack Overflow schema
-- This query retrieves the count of posts by type along with the total score and average view count,
-- and will help assess the performance based on the size and characteristics of posts.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    SUM(p.Score) AS TotalScore,
    AVG(p.ViewCount) AS AverageViewCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;
