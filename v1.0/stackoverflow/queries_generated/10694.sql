-- Performance benchmarking query: Count Posts and their related statistics by PostType
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore,
    SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
    AVG(CASE WHEN p.CreationDate IS NOT NULL THEN EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - p.CreationDate)) ELSE NULL END) AS AvgPostAgeInSeconds
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
