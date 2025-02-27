-- Performance benchmarking query
-- This query retrieves the count of posts, average score, and view count by post type,
-- along with user reputation statistics for the owners of those posts.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount,
    AVG(u.Reputation) AS AverageUserReputation
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= '2023-01-01'  -- Adjust date range for benchmarking
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;
