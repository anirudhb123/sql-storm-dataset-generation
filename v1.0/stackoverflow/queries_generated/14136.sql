-- Performance Benchmarking Query for the Stack Overflow Schema
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViewCount,
    AVG(DATEDIFF('second', p.CreationDate, COALESCE(p.LastActivityDate, CURRENT_TIMESTAMP))) AS AverageTimeToActivity,
    COUNT(DISTINCT u.Id) AS UniqueUsers
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
