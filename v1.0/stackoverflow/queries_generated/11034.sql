-- Performance Benchmarking Query

-- This query retrieves the total number of posts, along with the average score, 
-- the total number of views, and the total comments for each post type.
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViews,
    SUM(COALESCE(c.CommentCount, 0)) AS TotalComments
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount 
     FROM Comments 
     GROUP BY PostId) c ON p.Id = c.PostId
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
