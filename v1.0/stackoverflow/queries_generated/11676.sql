-- Performance benchmarking query to analyze post statistics and user engagement

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
    SUM(p.Score) AS TotalScore,
    AVG(u.Reputation) AS AverageUserReputation,
    COUNT(DISTINCT u.Id) AS UniqueUsers,
    COUNT(CASE WHEN p.LastActivityDate >= CURRENT_DATE - INTERVAL '30 days' THEN p.Id END) AS RecentActivityCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
