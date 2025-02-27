
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount,
    COUNT(DISTINCT p.OwnerUserId) AS UniqueUsers
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
