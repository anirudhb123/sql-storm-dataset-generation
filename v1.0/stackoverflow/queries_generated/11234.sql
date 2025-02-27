-- Performance benchmarking query for counting posts, average view count, and distribution of post types
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.ViewCount) AS AvgViewCount,
    MAX(p.ViewCount) AS MaxViewCount,
    MIN(p.ViewCount) AS MinViewCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;
