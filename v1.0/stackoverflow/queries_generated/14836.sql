-- Performance benchmarking query: Retrieve aggregated statistics on posts by type and user reputation.
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(u.Reputation) AS AverageUserReputation,
    SUM(p.Score) AS TotalScore,
    SUM(p.ViewCount) AS TotalViews,
    COUNT(DISTINCT p.OwnerUserId) AS UniqueUsers
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= NOW() - INTERVAL '30 days'  -- Filter to the last 30 days
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
