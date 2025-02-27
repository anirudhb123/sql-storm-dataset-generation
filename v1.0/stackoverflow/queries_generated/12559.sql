-- Performance benchmarking query to analyze average post view count and score by post type

SELECT 
    pt.Name AS PostType,
    AVG(p.ViewCount) AS AverageViewCount,
    AVG(p.Score) AS AverageScore,
    COUNT(p.Id) AS TotalPosts
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    AverageViewCount DESC;
