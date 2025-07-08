
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(DATEDIFF('SECOND', p.CreationDate, p.LastActivityDate)) AS AvgResponseTimeSeconds,
    SUM(COALESCE(p.Score, 0)) AS TotalScore
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
