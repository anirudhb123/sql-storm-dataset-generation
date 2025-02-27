-- Performance Benchmarking Query
-- This query measures the time it takes to retrieve posts with their associated data.
-- It selects a count of posts per type, joining with users and comment statistics.

SELECT 
    pt.Name AS PostTypeName,
    COUNT(p.Id) AS PostCount,
    COUNT(DISTINCT c.Id) AS CommentCount,
    AVG(u.Reputation) AS AvgUserReputation
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= '2023-01-01' -- Filtering for posts created in the year 2023
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;
