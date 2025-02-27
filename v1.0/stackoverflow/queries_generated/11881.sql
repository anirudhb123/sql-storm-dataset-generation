-- Performance Benchmarking Query for StackOverflow Schema

-- This query benchmark the total number of posts, average scores, and count of comments.
-- It aggregates data across posts and comments, demonstrating multiple joins and aggregations.

SELECT 
    p.PostTypeId,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(c.Score) AS TotalCommentScore,
    COUNT(c.Id) AS TotalComments,
    MAX(p.CreationDate) AS LatestPostDate
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    p.PostTypeId
ORDER BY 
    TotalPosts DESC;
