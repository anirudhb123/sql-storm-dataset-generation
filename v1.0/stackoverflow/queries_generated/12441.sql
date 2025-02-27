-- Performance Benchmarking Query

-- This query will retrieve the count of each post type along with the average score and view count, grouped by PostType.
-- It also includes the total number of comments for each post type.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount,
    SUM(COALESCE(c.CommentCount, 0)) AS TotalComments
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    (SELECT PostId, COUNT(Id) AS CommentCount 
     FROM Comments 
     GROUP BY PostId) c ON p.Id = c.PostId
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
