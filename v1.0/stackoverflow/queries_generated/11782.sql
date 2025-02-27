-- Performance benchmarking query to analyze post statistics by post type and user reputation

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    SUM(p.ViewCount) AS TotalViews,
    AVG(p.Score) AS AverageScore,
    COUNT(DISTINCT u.Id) AS UniqueUsers,
    AVG(u.Reputation) AS AverageUserReputation
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= NOW() - INTERVAL '30 days'  -- Filter for posts created in the last 30 days
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;
