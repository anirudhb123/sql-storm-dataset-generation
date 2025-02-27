-- Performance Benchmarking Query

-- This query retrieves the number of posts and their average scores by post type
SELECT 
    pt.Name AS PostType, 
    COUNT(p.Id) AS TotalPosts, 
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViews,
    COUNT(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 END) AS AcceptedAnswers
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
