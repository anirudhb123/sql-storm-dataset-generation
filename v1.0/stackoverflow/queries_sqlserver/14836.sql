
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
    p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - CAST(30 AS INT) 
GROUP BY 
    pt.Name, u.Reputation, p.Score, p.ViewCount, p.OwnerUserId
ORDER BY 
    TotalPosts DESC;
