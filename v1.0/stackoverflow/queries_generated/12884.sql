-- Performance Benchmarking Query

-- This query retrieves the count of posts grouped by PostType along with their average score,
-- total view count, and the latest activity date for each post type. 
-- This gives insights into the amount of activity and engagement each type of post generates.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViewCount,
    MAX(p.LastActivityDate) AS LatestActivityDate
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Id, pt.Name
ORDER BY 
    PostCount DESC;
