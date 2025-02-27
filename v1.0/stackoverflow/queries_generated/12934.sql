-- Performance Benchmarking Query
-- This query retrieves the average view count, score, and comment count for posts grouped by post type.
-- It also fetches the total number of posts and the maximum score for each post type for further performance analysis.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.ViewCount) AS AverageViewCount,
    AVG(p.Score) AS AverageScore,
    AVG(p.CommentCount) AS AverageCommentCount,
    MAX(p.Score) AS MaxScore
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'  -- Adjust the date interval for benchmarking as necessary
GROUP BY 
    pt.Name
ORDER BY 
    pt.Name;
