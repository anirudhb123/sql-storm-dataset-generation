-- Performance Benchmarking Query

-- This query retrieves the count of posts, the average score of those posts, 
-- and the statistics of the users who contributed to those posts, grouped by the post type.

SELECT 
    pt.Name AS PostType, 
    COUNT(p.Id) AS PostCount, 
    AVG(p.Score) AS AverageScore, 
    SUM(u.Reputation) AS TotalUserReputation,
    COUNT(DISTINCT u.Id) AS UniqueUsers
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
