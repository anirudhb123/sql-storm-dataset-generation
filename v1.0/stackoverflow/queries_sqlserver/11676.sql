
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
    SUM(p.Score) AS TotalScore,
    AVG(u.Reputation) AS AverageUserReputation,
    COUNT(DISTINCT u.Id) AS UniqueUsers,
    COUNT(CASE WHEN p.LastActivityDate >= CAST('2024-10-01' AS DATE) - 30 THEN p.Id END) AS RecentActivityCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    pt.Name,
    p.ViewCount,
    p.Score,
    u.Reputation,
    u.Id,
    p.LastActivityDate
ORDER BY 
    TotalPosts DESC;
