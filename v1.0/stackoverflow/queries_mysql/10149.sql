
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViews,
    COUNT(DISTINCT u.Id) AS UserCount,
    COUNT(c.Id) AS CommentCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    pt.Name, p.Id, p.Score, p.ViewCount, u.Id, c.Id
ORDER BY 
    PostType;
