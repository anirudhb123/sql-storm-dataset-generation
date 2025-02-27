-- Performance benchmarking query for the Stack Overflow schema

-- This query retrieves the total number of posts per post type along with the average score and view count.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
