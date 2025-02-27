-- Performance Benchmarking Query for StackOverflow Schema

-- This query retrieves the average score of posts grouped by post type,
-- along with the average number of comments and views. 
-- It helps to benchmark the performance based on popularity and engagement.

SELECT 
    pt.Name AS PostType, 
    AVG(p.Score) AS AverageScore, 
    AVG(p.CommentCount) AS AverageComments, 
    AVG(p.ViewCount) AS AverageViews,
    COUNT(p.Id) AS TotalPosts
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 YEAR'  -- Filter for posts created in the last year
GROUP BY 
    pt.Name
ORDER BY 
    AverageScore DESC;
