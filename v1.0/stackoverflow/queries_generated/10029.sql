-- Performance Benchmarking Query
-- This query retrieves the number of posts, average view count per post, 
-- and average score per post for each post type, along with user reputation

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.ViewCount) AS AverageViewCount,
    AVG(p.Score) AS AverageScore,
    AVG(u.Reputation) AS AverageUserReputation
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;
