
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViews,
    COUNT(DISTINCT p.OwnerUserId) AS UniqueUsers
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name, p.Id, p.Score, p.ViewCount, p.OwnerUserId
ORDER BY 
    TotalPosts DESC;
