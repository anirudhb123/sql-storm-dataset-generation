-- Performance benchmarking query for Stack Overflow schema

-- This query retrieves the count of posts, average score, and total view count 
-- grouped by post type, and joins necessary user and post types
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViewCount,
    COUNT(DISTINCT p.OwnerUserId) AS UniqueUsers
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;
