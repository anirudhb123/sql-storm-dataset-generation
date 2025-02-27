-- Performance benchmarking query to count posts, including various joins and aggregations
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViews,
    COUNT(DISTINCT c.Id) AS TotalComments,
    COUNT(DISTINCT bh.Id) AS TotalPostHistoryEntries
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    PostHistory bh ON p.Id = bh.PostId
WHERE 
    p.CreationDate >= '2023-01-01' -- Only consider posts created in 2023
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
