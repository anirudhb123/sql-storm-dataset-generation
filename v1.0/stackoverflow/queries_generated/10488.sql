-- Performance benchmarking query for the Stack Overflow schema

-- This query retrieves the count of posts, their average score, 
-- average view count and average comment count grouped by post type.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount,
    AVG(p.CommentCount) AS AverageCommentCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Note: This query will help benchmark the performance of post types
-- based on the number of posts, score, views, and comments.
