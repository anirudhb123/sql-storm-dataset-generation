-- Performance Benchmarking Query

-- This query retrieves statistics on posts, including the average score, view count, and the number of comments 
-- along with the users who own the posts. It is grouped by post type to analyze performance across different post types.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount,
    SUM(c.CommentCount) AS TotalComments,
    COUNT(DISTINCT p.OwnerUserId) AS UniquePostOwners
FROM 
    Posts p
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
