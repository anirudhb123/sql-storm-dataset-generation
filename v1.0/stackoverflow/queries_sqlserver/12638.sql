
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
    SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore,
    AVG(ISNULL(p.ViewCount, 0)) AS AverageViewsPerPost,
    AVG(ISNULL(p.Score, 0)) AS AverageScorePerPost,
    COUNT(DISTINCT CASE WHEN bh.UserId IS NOT NULL THEN bh.UserId END) AS UniqueEditors,
    COUNT(DISTINCT c.Id) AS TotalComments
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    PostHistory bh ON bh.PostId = p.Id
LEFT JOIN 
    Comments c ON c.PostId = p.Id
WHERE 
    p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(YEAR, 1, 0)
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
